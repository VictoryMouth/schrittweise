import WidgetKit
import SwiftUI
import HealthKit

// MARK: - Timeline Entry
struct StepEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let goal: Int
    let distanceKm: Double
    let calories: Int

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }

    var remainingSteps: Int {
        max(0, goal - steps)
    }

    var compactStepsString: String {
        if steps >= 10_000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        } else {
            return "\(steps)"
        }
    }

    var compactRemainingString: String {
        if remainingSteps >= 10_000 {
            return String(format: "%.1fk", Double(remainingSteps) / 1000.0)
        } else {
            return "\(remainingSteps)"
        }
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StepEntry {
        StepEntry(
            date: Date(),
            steps: 7_420,
            goal: 10_000,
            distanceKm: 5.4,
            calories: 320
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StepEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        Task {
            let entry = await Self.loadCurrentEntry()
            completion(entry.steps > 0 ? entry : StepEntry(
                date: entry.date,
                steps: 6_540,
                goal: entry.goal,
                distanceKm: entry.distanceKm,
                calories: entry.calories
            ))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        Task {
            let now = Date()
            let currentEntry = await Self.loadCurrentEntry()
            var entries = [currentEntry]

            // Regelmäßig neu laden – die Komplikation liest HealthKit dabei selbst aus,
            // die App muss dafür nicht geöffnet werden.
            let nextUpdate = now.addingTimeInterval(15 * 60)

            // Um Mitternacht automatisch auf 0 zurücksetzen
            let calendar = Calendar.current
            if let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)),
               midnight <= nextUpdate {
                entries.append(StepEntry(date: midnight, steps: 0, goal: currentEntry.goal, distanceKm: 0, calories: 0))
            }

            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
        }
    }

    /// Liest die aktuellen Werte direkt aus HealthKit; fällt auf den App-Group-Cache zurück,
    /// falls HealthKit gerade nicht lesbar ist (z. B. Uhr gesperrt).
    private static func loadCurrentEntry() async -> StepEntry {
        let cached = StepDataStore.loadTodaySteps()
        let cachedIsToday = Calendar.current.isDateInToday(cached.lastUpdated)

        var steps = cachedIsToday ? cached.steps : 0
        var distanceKm = cachedIsToday ? cached.distanceKm : 0
        var calories = cachedIsToday ? cached.calories : 0

        if let live = await ComplicationHealthReader.fetchToday() {
            // Schritte steigen über den Tag nur an – nie auf einen kleineren Wert zurückspringen
            steps = max(steps, live.steps)
            distanceKm = max(distanceKm, live.distanceKm)
            calories = max(calories, live.calories)

            StepDataStore.saveTodaySteps(steps: steps, goal: cached.goal, distanceKm: distanceKm, calories: calories)
        }

        return StepEntry(date: Date(), steps: steps, goal: cached.goal, distanceKm: distanceKm, calories: calories)
    }
}

// MARK: - HealthKit-Abfrage direkt in der Komplikation
enum ComplicationHealthReader {
    private static let healthStore = HKHealthStore()

    static func fetchToday() async -> (steps: Int, distanceKm: Double, calories: Int)? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        async let steps = sumForToday(.stepCount, unit: .count())
        async let distance = sumForToday(.distanceWalkingRunning, unit: .meter())
        async let calories = sumForToday(.activeEnergyBurned, unit: .kilocalorie())

        let (s, d, c) = await (steps, distance, calories)
        guard let s else { return nil }
        return (Int(s), (d ?? 0) / 1000.0, Int(c ?? 0))
    }

    private static func sumForToday(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error {
                    // "Keine Daten" heißt einfach 0 – alles andere (z. B. gesperrt) → Cache verwenden
                    if let hkError = error as? HKError, hkError.code == .errorNoData {
                        continuation.resume(returning: 0)
                    } else {
                        continuation.resume(returning: nil)
                    }
                    return
                }
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            healthStore.execute(query)
        }
    }
}

// =========================================================================
// MARK: - 1. DESIGN: SCHRITTE & FORTSCHRITT (Detaillierte Übersicht)
// =========================================================================

struct StepComplicationsEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularComplicationView(entry: entry)
        case .accessoryCircular:
            CircularComplicationView(entry: entry)
        case .accessoryCorner:
            CornerComplicationView(entry: entry)
        case .accessoryInline:
            InlineComplicationView(entry: entry)
        default:
            RectangularComplicationView(entry: entry)
        }
    }
}

struct RectangularComplicationView: View {
    var entry: StepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // Zeile 1: Titel + Prozent
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green)

                Text("Schritte")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 2)

                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }

            // Zeile 2: Schritte groß + Ziel & Distanz
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.steps.formatted())")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("/ \(entry.goal.formatted())")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                if entry.steps >= entry.goal {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.yellow)
                } else if entry.distanceKm > 0 {
                    Text(String(format: "%.1fkm", entry.distanceKm))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.cyan)
                        .lineLimit(1)
                }
            }

            // Zeile 3: Schlanker Fortschrittsbalken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(5, geo.size.width * CGFloat(entry.progress)), height: 5)
                }
            }
            .frame(height: 5)
            .padding(.top, 1)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct CircularComplicationView: View {
    var entry: StepEntry

    var body: some View {
        ZStack {
            Gauge(value: entry.progress) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 10, weight: .bold))
            } currentValueLabel: {
                Text(entry.compactStepsString)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(Gradient(colors: [.green, .mint, .cyan]))
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct CornerComplicationView: View {
    var entry: StepEntry

    var body: some View {
        Text("\(entry.steps.formatted())")
            .font(.system(.title3, design: .rounded).bold())
            .widgetCurvesContent()
            .widgetLabel {
                Gauge(value: entry.progress) {
                    Text("\(Int(entry.progress * 100))%")
                }
                .tint(Gradient(colors: [.green, .mint]))
            }
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

struct InlineComplicationView: View {
    var entry: StepEntry

    var body: some View {
        Label {
            Text("\(entry.steps.formatted()) (\(Int(entry.progress * 100))%)")
        } icon: {
            Image(systemName: "figure.walk")
        }
    }
}

public struct StepComplications: Widget {
    let kind: String = "StepComplications"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StepComplicationsEntryView(entry: entry)
        }
        .configurationDisplayName("Schritte & Fortschritt")
        .description("Zeigt die heutigen Schritte, das Tagesziel und den Fortschrittsbalken.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// =========================================================================
// MARK: - 2. DESIGN: NUR SCHRITTE (GROSS & MITTIG)
// =========================================================================

struct BigNumberEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            BigNumberRectangularView(entry: entry)
        case .accessoryCircular:
            BigNumberCircularView(entry: entry)
        case .accessoryCorner:
            CornerComplicationView(entry: entry)
        case .accessoryInline:
            InlineComplicationView(entry: entry)
        default:
            BigNumberRectangularView(entry: entry)
        }
    }
}

struct BigNumberRectangularView: View {
    var entry: StepEntry

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(alignment: .center, spacing: 4) {
                Spacer(minLength: 0)
                Image(systemName: "figure.walk")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.green)

                Text("\(entry.steps.formatted())")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct BigNumberCircularView: View {
    var entry: StepEntry

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: "figure.walk")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.green)

            Text("\(entry.steps.formatted())")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

public struct BigNumberStepWidget: Widget {
    let kind: String = "BigNumberStepWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BigNumberEntryView(entry: entry)
        }
        .configurationDisplayName("Nur Schritte (Groß)")
        .description("Zeigt ausschließlich die aktuelle Schrittzahl groß und zentriert an.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// =========================================================================
// MARK: - 3. DESIGN: VERBLEIBENDE SCHRITTE
// =========================================================================

struct RemainingStepsEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RemainingStepsRectangularView(entry: entry)
        case .accessoryCircular:
            RemainingStepsCircularView(entry: entry)
        case .accessoryCorner:
            CornerComplicationView(entry: entry)
        case .accessoryInline:
            InlineComplicationView(entry: entry)
        default:
            RemainingStepsRectangularView(entry: entry)
        }
    }
}

struct RemainingStepsRectangularView: View {
    var entry: StepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "target")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.yellow)

                Text(entry.remainingSteps == 0 ? "Ziel erreicht!" : "Noch verbleibend")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            if entry.remainingSteps == 0 {
                HStack(spacing: 4) {
                    Image(systemName: "party.popper.fill")
                        .foregroundStyle(.yellow)
                    Text("\(entry.steps.formatted())")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                    Text("Schritte")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.remainingSteps.formatted())")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.yellow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Schritte bis Ziel")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 4)

                    Capsule()
                        .fill(entry.remainingSteps == 0 ? Color.green : Color.yellow)
                        .frame(width: max(4, geo.size.width * CGFloat(entry.progress)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct RemainingStepsCircularView: View {
    var entry: StepEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "target")
                .font(.system(size: 10, weight: .bold))
        } currentValueLabel: {
            Text(entry.compactRemainingString)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.remainingSteps == 0 ? .green : .yellow)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

public struct RemainingStepsWidget: Widget {
    let kind: String = "RemainingStepsWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RemainingStepsEntryView(entry: entry)
        }
        .configurationDisplayName("Verbleibende Schritte")
        .description("Fokussiert sich auf die noch fehlenden Schritte bis zum Tagesziel.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

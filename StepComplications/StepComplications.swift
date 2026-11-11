import WidgetKit
import SwiftUI

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

    var progressPercent: Int {
        Int(progress * 100)
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

        let data = StepDataStore.loadTodaySteps()
        let entry = StepEntry(
            date: Date(),
            steps: data.steps > 0 ? data.steps : 6_540,
            goal: data.goal,
            distanceKm: data.distanceKm,
            calories: data.calories
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        let data = StepDataStore.loadTodaySteps()
        let currentEntry = StepEntry(
            date: Date(),
            steps: data.steps,
            goal: data.goal,
            distanceKm: data.distanceKm,
            calories: data.calories
        )

        // Nach 15 Minuten automatisch neu abfragen oder bei Datenänderung via reloadAllTimelines
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View Router
struct StepComplicationsEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            // Große rechteckige Komplikation (Modular, Ultra etc.)
            RectangularComplicationView(entry: entry)

        case .accessoryCircular:
            // Runde Komplikation
            CircularComplicationView(entry: entry)

        case .accessoryCorner:
            // Eck-Komplikation (z.B. Infograph)
            CornerComplicationView(entry: entry)

        case .accessoryInline:
            // Text-Zeile über/unter der Uhrzeit
            InlineComplicationView(entry: entry)

        default:
            RectangularComplicationView(entry: entry)
        }
    }
}

// MARK: - 1. Große Rechteckige Komplikation (.accessoryRectangular)
struct RectangularComplicationView: View {
    var entry: StepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Kopfzeile mit Icon, Titel und Prozent
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.green)
                Text("Schritte")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.progressPercent)%")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.green)
            }

            // Hauptwert: Große Schrittanzahl
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.steps.formatted())")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .contentTransition(.numericText())

                Text("/ \(entry.goal.formatted())")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            // Fortschrittsbalken und Restschritte / Distanz
            Gauge(value: min(Double(entry.steps), Double(entry.goal)), in: 0...Double(entry.goal)) {
                EmptyView()
            }
            .gaugeStyle(.linearCapacity)
            .tint(Gradient(colors: [.green, .mint]))

            HStack {
                if entry.steps >= entry.goal {
                    Text("Ziel erreicht! 🎉")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.yellow)
                } else {
                    Text("Noch \(entry.remainingSteps.formatted())")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if entry.distanceKm > 0 {
                    Text(String(format: "%.1f km", entry.distanceKm))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - 2. Runde Komplikation (.accessoryCircular)
struct CircularComplicationView: View {
    var entry: StepEntry

    var body: some View {
        Gauge(value: min(Double(entry.steps), Double(entry.goal)), in: 0...Double(entry.goal)) {
            Image(systemName: "figure.walk")
        } currentValueLabel: {
            Text(entry.compactStepsString)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.green)
    }
}

// MARK: - 3. Eck-Komplikation (.accessoryCorner)
struct CornerComplicationView: View {
    var entry: StepEntry

    var body: some View {
        Text("\(entry.steps.formatted())")
            .font(.system(.body, design: .rounded).bold())
            .widgetCurvesContent()
            .widgetLabel {
                Gauge(value: min(Double(entry.steps), Double(entry.goal)), in: 0...Double(entry.goal)) {
                    Text("Schritte")
                } currentValueLabel: {
                    Text("\(entry.steps)")
                }
                .tint(.green)
            }
    }
}

// MARK: - 4. Einzeilige Komplikation (.accessoryInline)
struct InlineComplicationView: View {
    var entry: StepEntry

    var body: some View {
        ViewThatFits {
            Label("\(entry.steps.formatted()) Schritte (\(entry.progressPercent)%)", systemImage: "figure.walk")
            Label("\(entry.steps.formatted()) Schritte", systemImage: "figure.walk")
            Label("\(entry.steps.formatted())", systemImage: "figure.walk")
        }
    }
}

// MARK: - Widget Definition
struct StepComplications: Widget {
    let kind: String = "StepComplications"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StepComplicationsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Schrittzähler")
        .description("Zeigt deine aktuellen Schritte und dein Tagesziel auf der Apple Watch an.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// MARK: - Previews für alle Komplikations-Größen
#Preview("Groß (Rectangular)", as: .accessoryRectangular) {
    StepComplications()
} timeline: {
    StepEntry(date: .now, steps: 8_420, goal: 10_000, distanceKm: 6.1, calories: 340)
}

#Preview("Rund (Circular)", as: .accessoryCircular) {
    StepComplications()
} timeline: {
    StepEntry(date: .now, steps: 8_420, goal: 10_000, distanceKm: 6.1, calories: 340)
}

#Preview("Ecke (Corner)", as: .accessoryCorner) {
    StepComplications()
} timeline: {
    StepEntry(date: .now, steps: 8_420, goal: 10_000, distanceKm: 6.1, calories: 340)
}

#Preview("Inline", as: .accessoryInline) {
    StepComplications()
} timeline: {
    StepEntry(date: .now, steps: 8_420, goal: 10_000, distanceKm: 6.1, calories: 340)
}

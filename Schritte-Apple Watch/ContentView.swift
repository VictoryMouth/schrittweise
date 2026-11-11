import SwiftUI

struct ContentView: View {
    @State private var healthKit = HealthKitManager()
    @State private var showingGoalSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Datum & Status
                    headerView

                    // Berechtigungs-Hinweis falls noch nicht autorisiert
                    if !healthKit.isAuthorized {
                        authorizationBanner
                    }

                    // Haupt-Fortschrittsring für Schritte
                    progressRingCard

                    // Metriken (Distanz, Kalorien, Verbleibend)
                    metricsGrid

                    // Wochenübersicht (Balkendiagramm)
                    weeklyChartView

                    // Ziel-Einstellung & Simulator-Helfer
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schrittzähler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await healthKit.fetchAllData()
                        }
                    } label: {
                        if healthKit.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable {
                await healthKit.fetchAllData()
            }
            .task {
                await healthKit.requestAuthorization()
            }
            .sheet(isPresented: $showingGoalSheet) {
                GoalSettingSheet(healthKit: healthKit)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Dein Tagesziel")
                    .font(.title3.weight(.bold))
            }
            Spacer()
            Button {
                showingGoalSheet = true
            } label: {
                Label("Ziel anpassen", systemImage: "pencil.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Authorization Banner
    private var authorizationBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health verbinden")
                        .font(.headline)
                    Text("Erlaube den Zugriff auf deine Schritte, um deine Daten synchron zu halten.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    await healthKit.requestAuthorization()
                }
            } label: {
                Text("Zugriff in Health erlauben")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Progress Ring Card
    private var progressRingCard: some View {
        VStack(spacing: 20) {
            ZStack {
                // Hintergrund-Ring
                Circle()
                    .stroke(Color.green.opacity(0.18), lineWidth: 22)

                // Vordergrund-Ring
                Circle()
                    .trim(from: 0, to: CGFloat(healthKit.progressPercentage))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.green, .mint, .cyan]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: healthKit.todaySteps)

                // Zentraler Text
                VStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                        .font(.title2.bold())
                        .foregroundStyle(.green)

                    Text("\(healthKit.todaySteps.formatted())")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())

                    Text("von \(healthKit.stepGoal.formatted())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(healthKit.progressPercentage * 100))%")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.18))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }
            .frame(width: 230, height: 230)
            .padding(.top, 10)

            if healthKit.todaySteps >= healthKit.stepGoal {
                Label("Tagesziel erreicht! 🎉", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
            } else {
                Text("Noch \(healthKit.remainingSteps.formatted()) Schritte bis zum Ziel")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        HStack(spacing: 12) {
            metricCard(
                title: "Distanz",
                value: String(format: "%.2f km", healthKit.todayDistanceKm),
                icon: "location.north.line.fill",
                color: .blue
            )

            metricCard(
                title: "Kalorien",
                value: "\(healthKit.todayCalories) kcal",
                icon: "flame.fill",
                color: .orange
            )

            metricCard(
                title: "Fortschritt",
                value: "\(Int(healthKit.progressPercentage * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(.headline, design: .rounded).bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Weekly Chart
    private var weeklyChartView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Letzte 7 Tage")
                    .font(.headline)
                Spacer()
                Text("Ziel: \(healthKit.stepGoal.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(healthKit.weeklySteps) { day in
                    VStack(spacing: 6) {
                        let maxHeight: CGFloat = 110
                        let highest = max(healthKit.stepGoal, healthKit.weeklySteps.map(\.steps).max() ?? 1)
                        let barHeight = highest > 0 ? (CGFloat(day.steps) / CGFloat(highest)) * maxHeight : 4

                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: maxHeight)

                            Capsule()
                                .fill(
                                    day.steps >= healthKit.stepGoal
                                    ? AnyShapeStyle(Color.green)
                                    : AnyShapeStyle(Color.accentColor)
                                )
                                .frame(height: max(6, barHeight))
                        }
                        .frame(width: 22)

                        Text(day.dayName)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)

                        Text("\(day.steps >= 1000 ? "\(day.steps / 1000)k" : "\(day.steps)")")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions / Simulator Helpers
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                healthKit.simulateSteps(count: 1000)
            } label: {
                Label("Testschritte simulieren (+1.000)", systemImage: "plus.circle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Goal Setting Sheet
struct GoalSettingSheet: View {
    @Bindable var healthKit: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal: Int = 10_000

    private let presets = [5_000, 8_000, 10_000, 12_000, 15_000, 20_000]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(selectedGoal.formatted()) Schritte")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("Tägliches Schrittziel")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Presets
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            selectedGoal = preset
                        } label: {
                            Text(preset.formatted())
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedGoal == preset ? Color.green : Color(.tertiarySystemGroupedBackground))
                                .foregroundStyle(selectedGoal == preset ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                Stepper(value: $selectedGoal, in: 1_000...50_000, step: 500) {
                    Text("Feinjustierung: ±500 Schritte")
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tagesziel festlegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        healthKit.updateGoal(selectedGoal)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                selectedGoal = healthKit.stepGoal
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ContentView()
}

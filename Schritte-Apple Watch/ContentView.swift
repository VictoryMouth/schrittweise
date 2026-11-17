import SwiftUI

struct ContentView: View {
    @State private var healthKit = HealthKitManager()
    @State private var showingGoalSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Status
                    if let errorMessage = healthKit.errorMessage {
                        errorBanner(errorMessage)
                    }

                    // Haupt-Fortschritts-Ring
                    progressHeroCard

                    // Quick-Metrics Grid (Distanz, Kalorien, Fortschritt)
                    metricsGrid

                    // Wochen-Trend Balkendiagramm
                    weeklyChartView

                    // Schnell-Aktionen (Ziel anpassen, Aktualisieren, Testdaten)
                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schrittweise")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await healthKit.fetchAllData()
                        }
                    } label: {
                        if healthKit.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .task {
                await healthKit.requestAuthorization()
            }
            .sheet(isPresented: $showingGoalSheet) {
                GoalSettingSheet(healthKit: healthKit)
            }
        }
    }

    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Progress Hero Card
    private var progressHeroCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Hintergrund-Ring
                Circle()
                    .stroke(Color.green.opacity(0.15), lineWidth: 22)

                // Dynamischer Fortschritts-Ring
                Circle()
                    .trim(from: 0, to: CGFloat(healthKit.progressPercentage))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.green, .mint, .cyan, .green]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.75), value: healthKit.todaySteps)

                // Innere Text-Statistiken
                VStack(spacing: 4) {
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
                        let barHeight = CGFloat(day.steps) / CGFloat(highest) * maxHeight
                        let isGoalMet = day.steps >= healthKit.stepGoal

                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
                                .frame(height: maxHeight)

                            Capsule()
                                .fill(isGoalMet ? Color.green : Color.blue.opacity(0.8))
                                .frame(height: max(6, barHeight))
                        }

                        Text(day.dayName)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
            .padding(.top, 8)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button {
                showingGoalSheet = true
            } label: {
                Label("Tagesziel ändern & Einstellungen", systemImage: "target")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            #if DEBUG
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
            #endif
        }
    }
}

// MARK: - Goal Setting Sheet
struct GoalSettingSheet: View {
    @Bindable var healthKit: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal: Int = 10_000
    @State private var notificationsEnabled: Bool = true

    private let presets = [5_000, 8_000, 10_000, 12_000, 15_000, 20_000]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("\(selectedGoal.formatted()) Schritte")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text("Tägliches Schrittziel")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 10)

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

                    Toggle(isOn: $notificationsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Motivations-Mitteilungen")
                                .font(.body)
                            Text("Bei 25%, 50%, 75%, 90% und 100% des Tagesziels")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.green)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Spacer()
                }
                .padding(20)
            }
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
                        MotivationNotificationManager.shared.isEnabled = notificationsEnabled
                        if notificationsEnabled {
                            MotivationNotificationManager.shared.requestAuthorization()
                        }
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                selectedGoal = healthKit.stepGoal
                notificationsEnabled = MotivationNotificationManager.shared.isEnabled
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ContentView()
}

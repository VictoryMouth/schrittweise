import SwiftUI

struct ContentView: View {
    @State private var healthKit = WatchHealthKitManager.shared
    @State private var showingGoalSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Haupt-Fortschrittsanzeige
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 12)

                        Circle()
                            .trim(from: 0, to: CGFloat(healthKit.progressPercentage))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.green, .mint, .cyan]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: healthKit.todaySteps)

                        VStack(spacing: 2) {
                            Image(systemName: "figure.walk")
                                .font(.headline)
                                .foregroundStyle(.green)

                            Text("\(healthKit.todaySteps.formatted())")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())

                            Text("Ziel: \(healthKit.stepGoal.formatted())")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 130, height: 130)
                    .padding(.top, 4)

                    // Prozent & Status
                    HStack {
                        Text("\(Int(healthKit.progressPercentage * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text("•")
                            .foregroundStyle(.secondary)
                        if healthKit.todaySteps >= healthKit.stepGoal {
                            Text("Erreicht! 🎉")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.yellow)
                        } else {
                            Text("Noch \(healthKit.remainingSteps.formatted())")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Metriken Karten
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Distanz", systemImage: "location.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                            Text(String(format: "%.2f km", healthKit.todayDistanceKm))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Label("Kalorien", systemImage: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                            Text("\(healthKit.todayCalories) kcal")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Aktionen
                    VStack(spacing: 6) {
                        Button {
                            showingGoalSheet = true
                        } label: {
                            Label("Ziel ändern", systemImage: "target")
                                .font(.system(size: 13))
                        }

                        #if DEBUG
                        Button {
                            healthKit.simulateSteps(count: 500)
                        } label: {
                            Label("+500 Test", systemImage: "plus")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        #endif
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Schrittweise")
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
                WatchGoalSheet(healthKit: healthKit)
            }
        }
    }
}

// MARK: - Watch Goal Sheet
struct WatchGoalSheet: View {
    @Bindable var healthKit: WatchHealthKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var goal: Double = 10_000
    @State private var notificationsEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Tagesziel")
                    .font(.headline)

                Text("\(Int(goal).formatted())")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                Slider(value: $goal, in: 2_000...30_000, step: 1_000)
                    .tint(.green)

                Toggle("Motivation (25%, 50%, 75%, 90%)", isOn: $notificationsEnabled)
                    .font(.footnote)
                    .tint(.green)

                Button("Speichern") {
                    healthKit.updateGoal(Int(goal))
                    MotivationNotificationManager.shared.isEnabled = notificationsEnabled
                    if notificationsEnabled {
                        MotivationNotificationManager.shared.requestAuthorization()
                    }
                    dismiss()
                }
                .tint(.green)
            }
            .padding()
        }
        .onAppear {
            goal = Double(healthKit.stepGoal)
            notificationsEnabled = MotivationNotificationManager.shared.isEnabled
        }
    }
}

#Preview {
    ContentView()
}

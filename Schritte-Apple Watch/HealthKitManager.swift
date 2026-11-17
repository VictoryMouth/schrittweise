import Foundation
import Observation
import HealthKit

@Observable
@MainActor
final class HealthKitManager {
    var todaySteps: Int = 0
    var stepGoal: Int = 10_000
    var todayDistanceKm: Double = 0.0
    var todayCalories: Int = 0
    var weeklySteps: [DailyStepRecord] = []
    var isAuthorized: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var progressPercentage: Double {
        guard stepGoal > 0 else { return 0 }
        return min(Double(todaySteps) / Double(stepGoal), 1.0)
    }

    var remainingSteps: Int {
        max(0, stepGoal - todaySteps)
    }

    init() {
        // Initiale Werte aus Cache laden
        let cached = StepDataStore.loadTodaySteps()
        self.todaySteps = cached.steps
        self.stepGoal = cached.goal
        self.todayDistanceKm = cached.distanceKm
        self.todayCalories = cached.calories

        // 7 leere Tage als Platzhalter vorbelegen
        self.weeklySteps = Self.makePlaceholderWeek()
    }

    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            errorMessage = "HealthKit ist auf diesem Gerät nicht verfügbar."
            return
        }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            errorMessage = "Schrittzähler-Datentyp nicht verfügbar."
            return
        }

        var readTypes: Set<HKObjectType> = [stepType]
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            readTypes.insert(distanceType)
        }
        if let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            readTypes.insert(calorieType)
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            errorMessage = nil
            MotivationNotificationManager.shared.requestAuthorization()
            await fetchAllData()
            startObservingStepChanges()
        } catch {
            errorMessage = "HealthKit-Zugriff fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    func fetchAllData() async {
        guard isHealthKitAvailable else { return }
        isLoading = true

        async let steps = fetchStepsForToday()
        async let distance = fetchDistanceForToday()
        async let calories = fetchCaloriesForToday()
        async let week = fetchWeeklyStepHistory()

        let (s, d, c, w) = await (steps, distance, calories, week)

        self.todaySteps = s
        self.todayDistanceKm = d
        self.todayCalories = c
        if !w.isEmpty {
            self.weeklySteps = w
        }
        self.isLoading = false

        // Im Cache / AppGroup für Widgets & Watch sichern
        StepDataStore.saveTodaySteps(
            steps: self.todaySteps,
            goal: self.stepGoal,
            distanceKm: self.todayDistanceKm,
            calories: self.todayCalories
        )

        // Motivations-Mitteilungen prüfen
        MotivationNotificationManager.shared.checkAndNotify(steps: self.todaySteps, goal: self.stepGoal)
    }

    func updateGoal(_ newGoal: Int) {
        let clamped = max(1_000, min(100_000, newGoal))
        self.stepGoal = clamped
        StepDataStore.saveTodaySteps(
            steps: self.todaySteps,
            goal: clamped,
            distanceKm: self.todayDistanceKm,
            calories: self.todayCalories
        )
    }

    // MARK: - HealthKit Abfragen

    private func fetchStepsForToday() async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return todaySteps }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let count = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(count))
            }
            healthStore.execute(query)
        }
    }

    private func fetchDistanceForToday() async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return todayDistanceKm }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let distanceMeters = stats?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                continuation.resume(returning: distanceMeters / 1000.0)
            }
            healthStore.execute(query)
        }
    }

    private func fetchCaloriesForToday() async -> Int {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return todayCalories }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let kcal = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: Int(kcal))
            }
            healthStore.execute(query)
        }
    }

    private func fetchWeeklyStepHistory() async -> [DailyStepRecord] {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }

        var interval = DateComponents()
        interval.day = 1

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, _ in
                var records: [DailyStepRecord] = []
                if let results = results {
                    results.enumerateStatistics(from: startDate, to: Date()) { stats, _ in
                        let count = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                        records.append(DailyStepRecord(date: stats.startDate, steps: Int(count)))
                    }
                }
                continuation.resume(returning: records)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Hintergrundüberwachung

    private func startObservingStepChanges() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        if let existing = observerQuery {
            healthStore.stop(existing)
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            Task { @MainActor in
                await self?.fetchAllData()
            }
        }

        self.observerQuery = query
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { _, _ in }
    }

    private static func makePlaceholderWeek() -> [DailyStepRecord] {
        let calendar = Calendar.current
        var items: [DailyStepRecord] = []
        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                items.append(DailyStepRecord(date: calendar.startOfDay(for: date), steps: 0))
            }
        }
        return items
    }

    func simulateSteps(count: Int) {
        self.todaySteps += count
        self.todayDistanceKm += Double(count) * 0.00075
        self.todayCalories += Int(Double(count) * 0.04)

        if let lastIndex = weeklySteps.indices.last {
            let last = weeklySteps[lastIndex]
            weeklySteps[lastIndex] = DailyStepRecord(date: last.date, steps: last.steps + count)
        }

        StepDataStore.saveTodaySteps(
            steps: self.todaySteps,
            goal: self.stepGoal,
            distanceKm: self.todayDistanceKm,
            calories: self.todayCalories
        )

        // Motivations-Mitteilungen prüfen
        MotivationNotificationManager.shared.checkAndNotify(steps: self.todaySteps, goal: self.stepGoal)
    }
}

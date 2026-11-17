import Foundation
import Observation
import HealthKit
import WidgetKit

@Observable
@MainActor
final class WatchHealthKitManager {
    static let shared = WatchHealthKitManager()

    var todaySteps: Int = 0
    var stepGoal: Int = 10_000
    var todayDistanceKm: Double = 0.0
    var todayCalories: Int = 0
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
        let cached = StepDataStore.loadTodaySteps()
        self.todaySteps = cached.steps
        self.stepGoal = cached.goal
        self.todayDistanceKm = cached.distanceKm
        self.todayCalories = cached.calories
    }

    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            errorMessage = "HealthKit nicht verfügbar."
            return
        }

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        var readTypes: Set<HKObjectType> = [stepType]
        if let dist = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            readTypes.insert(dist)
        }
        if let cal = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            readTypes.insert(cal)
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            self.isAuthorized = true
            MotivationNotificationManager.shared.requestAuthorization()
            await fetchAllData()
            startObservingStepChanges()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func fetchAllData() async {
        guard isHealthKitAvailable else { return }
        isLoading = true

        async let steps = fetchStepsForToday()
        async let distance = fetchDistanceForToday()
        async let calories = fetchCaloriesForToday()

        let (s, d, c) = await (steps, distance, calories)

        self.todaySteps = s
        self.todayDistanceKm = d
        self.todayCalories = c
        self.isLoading = false

        // In Cache & AppGroup speichern
        StepDataStore.saveTodaySteps(
            steps: self.todaySteps,
            goal: self.stepGoal,
            distanceKm: self.todayDistanceKm,
            calories: self.todayCalories
        )

        // Motivations-Mitteilungen prüfen
        MotivationNotificationManager.shared.checkAndNotify(steps: self.todaySteps, goal: self.stepGoal)

        // Komplikationen auf dem Zifferblatt sofort aktualisieren!
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateGoal(_ newGoal: Int) {
        let clamped = max(1_000, min(50_000, newGoal))
        self.stepGoal = clamped
        StepDataStore.saveTodaySteps(
            steps: self.todaySteps,
            goal: clamped,
            distanceKm: self.todayDistanceKm,
            calories: self.todayCalories
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

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
            let query = HKStatisticsQuery(quantityType:  calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let kcal = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: Int(kcal))
            }
            healthStore.execute(query)
        }
    }

    func startObservingStepChanges() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        if let existing = observerQuery {
            healthStore.stop(existing)
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }
            Task { @MainActor in
                await self?.fetchAllData()
                completionHandler()
            }
        }

        self.observerQuery = query
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { _, _ in }
    }

    func simulateSteps(count: Int) {
        self.todaySteps += count
        self.todayDistanceKm += Double(count) * 0.00075
        self.todayCalories += Int(Double(count) * 0.04)

        StepDataStore.saveTodaySteps(
            steps: self.todaySteps,
            goal: self.stepGoal,
            distanceKm: self.todayDistanceKm,
            calories: self.todayCalories
        )

        // Motivations-Mitteilungen prüfen
        MotivationNotificationManager.shared.checkAndNotify(steps: self.todaySteps, goal: self.stepGoal)

        WidgetCenter.shared.reloadAllTimelines()
    }
}

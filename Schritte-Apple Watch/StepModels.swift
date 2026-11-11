import Foundation

/// Ein Datenmodell für einen einzelnen Tagesschrittwert
struct DailyStepRecord: Identifiable, Hashable {
    let id: UUID = UUID()
    let date: Date
    let steps: Int

    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        return formatter.string(from: date)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM."
        return formatter.string(from: date)
    }
}

/// Gemeinsamer Speicher für Schritte und Einstellungen (über AppGroup und UserDefaults)
struct StepDataStore {
    static let appGroupID = "group.com.siegmundmurer.schritte"
    static let stepsKey = "todayStepsCount"
    static let goalKey = "dailyStepGoal"
    static let lastUpdatedKey = "stepLastUpdated"
    static let distanceKmKey = "todayDistanceKm"
    static let caloriesKey = "todayCalories"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
    }

    static func saveTodaySteps(steps: Int, goal: Int, distanceKm: Double, calories: Int) {
        let defaults = sharedDefaults
        defaults.set(steps, forKey: stepsKey)
        defaults.set(goal, forKey: goalKey)
        defaults.set(distanceKm, forKey: distanceKmKey)
        defaults.set(calories, forKey: caloriesKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastUpdatedKey)

        UserDefaults.standard.set(steps, forKey: stepsKey)
        UserDefaults.standard.set(goal, forKey: goalKey)
        UserDefaults.standard.set(distanceKm, forKey: distanceKmKey)
        UserDefaults.standard.set(calories, forKey: caloriesKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUpdatedKey)
    }

    static func loadTodaySteps() -> (steps: Int, goal: Int, distanceKm: Double, calories: Int, lastUpdated: Date) {
        let defaults = sharedDefaults
        let hasStoredSteps = defaults.object(forKey: stepsKey) != nil
        let steps = hasStoredSteps ? defaults.integer(forKey: stepsKey) : UserDefaults.standard.integer(forKey: stepsKey)

        var goal = defaults.integer(forKey: goalKey)
        if goal <= 0 {
            goal = UserDefaults.standard.integer(forKey: goalKey)
        }
        if goal <= 0 {
            goal = 10_000
        }

        let distanceKm = defaults.object(forKey: distanceKmKey) != nil ? defaults.double(forKey: distanceKmKey) : UserDefaults.standard.double(forKey: distanceKmKey)
        let calories = defaults.object(forKey: caloriesKey) != nil ? defaults.integer(forKey: caloriesKey) : UserDefaults.standard.integer(forKey: caloriesKey)
        let timestamp = defaults.double(forKey: lastUpdatedKey)
        let date = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date()

        return (steps, goal, distanceKm, calories, date)
    }
}

import Foundation
import UserNotifications

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

// MARK: - Motivations-Meilensteine & Mitteilungen
enum StepMilestone: Int, CaseIterable {
    case quarter = 25
    case half = 50
    case threeQuarters = 75
    case ninety = 90
    case hundred = 100

    var title: String {
        switch self {
        case .quarter: return "Starker Start! 👟"
        case .half: return "Halbzeit erreicht! ⚡️"
        case .threeQuarters: return "Schon 75%! Weiter so! 🔥"
        case .ninety: return "Fast am Ziel (90%)! 🏁"
        case .hundred: return "Tagesziel erreicht! 🏆"
        }
    }

    func message(steps: Int, goal: Int) -> String {
        switch self {
        case .quarter:
            return "Klasse, 25% deines Ziels (\(steps.formatted()) von \(goal.formatted()) Schritten) sind geschafft. Jeder Schritt zählt!"
        case .half:
            return "Super gemacht! Die Hälfte (\(steps.formatted()) Schritte) ist voll. Der Rest ist jetzt ein Klacks!"
        case .threeQuarters:
            return "Wahnsinn, drei Viertel sind gepackt! Nur noch \(max(0, goal - steps).formatted()) Schritte bis zur Ziellinie."
        case .ninety:
            return "Endspurt! Bei 90% fehlen nur noch die letzten Meter. Hol dir das Tagesziel!"
        case .hundred:
            return "Glückwunsch! 🎉 Du hast deine \(goal.formatted()) Schritte für heute gemeistert. Starke Leistung!"
        }
    }
}

final class MotivationNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MotivationNotificationManager()

    private let notificationsEnabledKey = "motivationalNotificationsEnabled"
    private let notifiedMilestonesPrefix = "notifiedMilestones_"

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: notificationsEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: notificationsEnabledKey)
        }
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func checkAndNotify(steps: Int, goal: Int) {
        guard isEnabled, goal > 0 else { return }

        let calendar = Calendar.current
        let todayString = ISO8601DateFormatter().string(from: calendar.startOfDay(for: Date()))
        let dayKey = "\(notifiedMilestonesPrefix)\(todayString)"

        var notified = Set(UserDefaults.standard.array(forKey: dayKey) as? [Int] ?? [])
        let currentPercent = Int((Double(steps) / Double(goal)) * 100)

        for milestone in StepMilestone.allCases {
            if currentPercent >= milestone.rawValue && !notified.contains(milestone.rawValue) {
                sendNotification(for: milestone, steps: steps, goal: goal)
                notified.insert(milestone.rawValue)
            }
        }

        UserDefaults.standard.set(Array(notified), forKey: dayKey)
    }

    private func sendNotification(for milestone: StepMilestone, steps: Int, goal: Int) {
        let content = UNMutableNotificationContent()
        content.title = milestone.title
        content.body = milestone.message(steps: steps, goal: goal)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "step_milestone_\(milestone.rawValue)_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}

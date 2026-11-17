import WatchKit
import HealthKit
import WidgetKit

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        Task { @MainActor in
            await WatchHealthKitManager.shared.requestAuthorization()
            WatchHealthKitManager.shared.startObservingStepChanges()
            scheduleNextBackgroundRefresh()
        }
    }

    func applicationDidEnterBackground() {
        scheduleNextBackgroundRefresh()
    }

    func applicationDidBecomeActive() {
        Task { @MainActor in
            await WatchHealthKitManager.shared.fetchAllData()
        }
    }

    // MARK: - Background Tasks
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let appRefreshTask as WKApplicationRefreshBackgroundTask:
                Task { @MainActor in
                    await WatchHealthKitManager.shared.fetchAllData()
                    scheduleNextBackgroundRefresh()
                    appRefreshTask.setTaskCompletedWithSnapshot(false)
                }
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func scheduleNextBackgroundRefresh() {
        // Alle 15 Minuten im Hintergrund aufwachen und die Timeline auffrischen
        let targetDate = Date().addingTimeInterval(15 * 60)
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { error in
            #if DEBUG
            if let error = error {
                print("Failed to schedule background refresh: \(error.localizedDescription)")
            }
            #endif
        }
    }
}

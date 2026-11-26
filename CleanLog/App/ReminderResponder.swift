import Foundation
import Observation
import UserNotifications

@Observable
final class ReminderResponder: NSObject, UNUserNotificationCenterDelegate {
    private(set) var requestedReport: MonthKey?

    func open(_ month: MonthKey) {
        requestedReport = month
    }

    func takeRequestedReport() -> MonthKey? {
        defer { requestedReport = nil }
        return requestedReport
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let month = ReminderRequest.month(from: userInfo) else { return }
        await open(month)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

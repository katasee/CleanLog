import UIKit
import UserNotifications

final class SystemNotifications: ReminderCenter, NotificationPermission {
    private let center = UNUserNotificationCenter.current()

    var settingsURL: URL {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            preconditionFailure("The notification settings URL does not parse")
        }
        return url
    }

    func authorization() async -> NotificationAuthorization {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .authorized
        @unknown default: .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func schedule(_ request: ReminderRequest) async throws {
        try await center.add(notificationRequest(for: request))
    }

    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [ReminderRequest.identifier])
    }

    private func notificationRequest(for request: ReminderRequest) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.userInfo = request.userInfo
        let trigger = UNCalendarNotificationTrigger(dateMatching: request.fireDate, repeats: false)
        return UNNotificationRequest(
            identifier: ReminderRequest.identifier,
            content: content,
            trigger: trigger
        )
    }
}

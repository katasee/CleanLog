import UserNotifications

final class SystemNotifications: ReminderCenter {
    private let center = UNUserNotificationCenter.current()

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

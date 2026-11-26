import Foundation

enum NotificationAuthorization: Equatable {
    case notDetermined
    case denied
    case authorized
}

protocol NotificationPermission: AnyObject {
    var settingsURL: URL { get }
    func authorization() async -> NotificationAuthorization
    func requestAuthorization() async throws -> Bool
}

#if DEBUG
    final class FakeNotificationPermission: NotificationPermission {
        private var current: NotificationAuthorization
        private let grants: Bool

        private(set) var requestCount = 0

        init(_ authorization: NotificationAuthorization = .authorized, grants: Bool = true) {
            current = authorization
            self.grants = grants
        }

        var settingsURL: URL {
            URL(filePath: "/settings/notifications")
        }

        func set(_ authorization: NotificationAuthorization) {
            current = authorization
        }

        func authorization() async -> NotificationAuthorization {
            current
        }

        func requestAuthorization() async throws -> Bool {
            requestCount += 1
            current = grants ? .authorized : .denied
            return grants
        }
    }
#endif

protocol ReminderCenter: AnyObject {
    func schedule(_ request: ReminderRequest) async throws
    func cancelReminder()
}

#if DEBUG
    final class FakeReminderCenter: ReminderCenter {
        private(set) var pending: ReminderRequest?
        private(set) var scheduleCount = 0
        private(set) var cancelCount = 0

        func schedule(_ request: ReminderRequest) async throws {
            scheduleCount += 1
            pending = request
        }

        func cancelReminder() {
            cancelCount += 1
            pending = nil
        }
    }
#endif

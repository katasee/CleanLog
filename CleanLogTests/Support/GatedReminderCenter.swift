import Foundation

@testable import CleanLog

final class GatedReminderCenter: ReminderCenter {
    enum Event: Equatable {
        case scheduled
        case cancelled
    }

    private var waiting: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false
    private(set) var pending: ReminderRequest?
    private(set) var events: [Event] = []

    var hasWaitingSchedule: Bool {
        !waiting.isEmpty
    }

    func open() {
        isOpen = true
        waiting.forEach { $0.resume() }
        waiting = []
    }

    func schedule(_ request: ReminderRequest) async throws {
        if !isOpen {
            await withCheckedContinuation { waiting.append($0) }
        }
        pending = request
        events.append(.scheduled)
    }

    func cancelReminder() {
        pending = nil
        events.append(.cancelled)
    }
}

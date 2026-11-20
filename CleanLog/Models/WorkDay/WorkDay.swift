import Foundation

/// Everything recorded for one calendar day: the planned apartments and the time worked.
/// Rules are methods returning a changed copy, so a repository only stores what they produce.
nonisolated struct WorkDay: Sendable, Hashable, Identifiable {
    let id: UUID
    let day: DayKey
    var entries: [DayEntry]
    var sessions: [WorkSession]
    /// Replaces the measured sessions when set — for a timer that was forgotten.
    var manualDuration: Duration?
    var isTimerFinished: Bool

    static func empty(_ day: DayKey) -> WorkDay {
        WorkDay(
            id: UUID(),
            day: day,
            entries: [],
            sessions: [],
            manualDuration: nil,
            isTimerFinished: false
        )
    }

    var earned: Money {
        entries.filter(\.isCleaned).map(\.price).sum()
    }

    var planned: Money {
        entries.map(\.price).sum()
    }

    var cleanedCount: Int {
        entries.count { $0.isCleaned }
    }

    var hasCleanedEntries: Bool {
        entries.contains { $0.isCleaned }
    }
}

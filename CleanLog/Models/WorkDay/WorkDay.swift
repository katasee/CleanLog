import Foundation

nonisolated struct WorkDay: Sendable, Hashable, Identifiable {
    let id: UUID
    let day: DayKey
    var entries: [DayEntry]
    var sessions: [WorkSession]
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

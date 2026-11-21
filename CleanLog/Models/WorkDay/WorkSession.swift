import Foundation

nonisolated struct WorkSession: Sendable, Hashable, Identifiable {
    let id: UUID
    let start: Date
    var end: Date?

    func duration(now: Date) -> Duration {
        let seconds = (end ?? now).timeIntervalSince(start)
        return .seconds(max(seconds, 0))
    }
}

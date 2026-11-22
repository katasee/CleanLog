import Foundation

nonisolated enum DayKind: Sendable, Equatable {
    case past
    case today
    case future
}

extension DayKey {
    nonisolated func kind(relativeTo today: DayKey) -> DayKind {
        if self < today { return .past }
        return self == today ? .today : .future
    }
}

import Foundation

nonisolated enum WorkDayError: Error, Equatable {
    /// Nothing can be cleaned in advance.
    case futureDay
    /// The timer runs only on today.
    case notToday
    /// The timer cannot make this move from its current state.
    case timerState
    case entryNotFound
}

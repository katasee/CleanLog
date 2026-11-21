import Foundation

nonisolated enum WorkDayError: Error, Equatable {
    case futureDay
    case notToday
    case timerState
    case entryNotFound
}

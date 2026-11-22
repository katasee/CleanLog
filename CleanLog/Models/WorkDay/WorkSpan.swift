import Foundation

nonisolated struct WorkSpan: Sendable, Equatable {
    let start: Date
    let end: Date?
    let pauses: Duration
}

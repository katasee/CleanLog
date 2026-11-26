import Foundation

nonisolated enum WorkDayDuplicates {
    static func merged(_ copies: [Revision<WorkDay>]) -> Revision<WorkDay> {
        precondition(!copies.isEmpty, "A merge needs at least one copy of the day")
        let ordered = copies.sorted(by: isNewer).map(\.value)
        let newest = ordered[0]
        let day = WorkDay(
            id: ordered.map(\.id).min { $0.uuidString < $1.uuidString } ?? newest.id,
            day: newest.day,
            entries: mergedEntries(ordered.flatMap(\.entries)),
            sessions: foldedSessions(ordered.flatMap(\.sessions)),
            manualDuration: ordered.lazy.compactMap(\.manualDuration).first,
            isTimerFinished: newest.isTimerFinished,
            isTimeDropped: newest.isTimeDropped
        )
        return Revision(value: day, changedAt: copies.map(\.changedAt).max() ?? .distantPast)
    }

    private static func isNewer(_ lhs: Revision<WorkDay>, _ rhs: Revision<WorkDay>) -> Bool {
        if lhs.changedAt != rhs.changedAt {
            return lhs.changedAt > rhs.changedAt
        }
        return lhs.value.id.uuidString < rhs.value.id.uuidString
    }

    private static func mergedEntries(_ entries: [DayEntry]) -> [DayEntry] {
        var merged: [DayEntry] = []
        for entry in entries {
            guard let index = merged.firstIndex(where: { $0.apartmentID == entry.apartmentID }) else {
                merged.append(entry)
                continue
            }
            merged[index] = merged[index].keepingTick(of: entry)
        }
        return merged
    }

    private static func foldedSessions(_ sessions: [WorkSession]) -> [WorkSession] {
        let sorted = sessions.sorted { ($0.start, $0.id.uuidString) < ($1.start, $1.id.uuidString) }
        var folded: [WorkSession] = []
        for session in sorted {
            if let last = folded.last, session.start <= last.foldEnd {
                folded[folded.count - 1].end = last.foldEnd >= session.foldEnd ? last.end : session.end
            } else {
                folded.append(session)
            }
        }
        return folded
    }
}

extension DayEntry {
    fileprivate nonisolated func keepingTick(of other: DayEntry) -> DayEntry {
        var copy = self
        copy.isCleaned = isCleaned || other.isCleaned
        copy.cleanedAt = [self, other].filter(\.isCleaned).compactMap(\.cleanedAt).min()
        return copy
    }
}

extension WorkSession {
    fileprivate nonisolated var foldEnd: Date {
        end ?? .distantFuture
    }
}

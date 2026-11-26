import Foundation

nonisolated enum WorkDayDuplicates {
    static func merged(_ copies: [Revision<WorkDay>]) -> Revision<WorkDay> {
        let ordered = Revision.newestFirst(copies)
        guard let newest = ordered.first, let survivorID = Revision.survivorID(among: copies) else {
            preconditionFailure("A merge needs at least one copy of the day")
        }
        let values = ordered.map(\.value)
        let day = WorkDay(
            id: survivorID,
            day: newest.value.day,
            entries: mergedEntries(values.flatMap(\.entries)),
            sessions: foldedSessions(values.flatMap(\.sessions)),
            manualDuration: values.lazy.compactMap(\.manualDuration).first,
            isTimerFinished: newest.value.isTimerFinished,
            isTimeDropped: newest.value.isTimeDropped
        )
        return Revision(value: day, changedAt: newest.changedAt)
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

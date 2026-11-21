import Foundation
import SwiftData

extension WorkDayRecord {
    var domain: WorkDay {
        guard let day = DayKey(storageValue: dayValue) else {
            preconditionFailure("Stored day value \(dayValue) is not a day")
        }
        return WorkDay(
            id: id,
            day: day,
            entries: (entries ?? []).sorted { $0.position < $1.position }.map(\.domain),
            sessions: (sessions ?? []).sorted { $0.position < $1.position }.map(\.domain),
            manualDuration: manualDurationSeconds.map { .seconds($0) },
            isTimerFinished: isTimerFinished
        )
    }

    func apply(_ workDay: WorkDay) {
        guard let modelContext else {
            preconditionFailure("A work day is applied only to a record in a context")
        }
        id = workDay.id
        dayValue = workDay.day.storageValue
        manualDurationSeconds = workDay.manualDuration.map { Int($0.components.seconds) }
        isTimerFinished = workDay.isTimerFinished
        entries = modelContext.synced(entries ?? [], to: workDay.entries, make: DayEntryRecord.init) {
            $0.apply($1, position: $2)
        }
        sessions = modelContext.synced(sessions ?? [], to: workDay.sessions, make: WorkSessionRecord.init) {
            $0.apply($1, position: $2)
        }
    }
}

extension DayEntryRecord {
    fileprivate var domain: DayEntry {
        DayEntry(
            id: id,
            apartmentID: apartmentID,
            name: name,
            price: Money(minorUnits: priceMinorUnits),
            isReportedSeparately: isReportedSeparately,
            sortOrder: sortOrder,
            isCleaned: isCleaned,
            cleanedAt: cleanedAt
        )
    }

    fileprivate func apply(_ entry: DayEntry, position: Int) {
        id = entry.id
        self.position = position
        apartmentID = entry.apartmentID
        name = entry.name
        priceMinorUnits = entry.price.minorUnits
        isReportedSeparately = entry.isReportedSeparately
        sortOrder = entry.sortOrder
        isCleaned = entry.isCleaned
        cleanedAt = entry.cleanedAt
    }
}

extension WorkSessionRecord {
    fileprivate var domain: WorkSession {
        WorkSession(id: id, start: start, end: end)
    }

    fileprivate func apply(_ session: WorkSession, position: Int) {
        id = session.id
        self.position = position
        start = session.start
        end = session.end
    }
}

extension ModelContext {
    fileprivate nonisolated func synced<Record: PersistentModel, Value: Identifiable>(
        _ records: [Record],
        to values: [Value],
        make: () -> Record,
        apply: (Record, Value, Int) -> Void
    ) -> [Record] where Record.ID == UUID, Value.ID == UUID {
        let recordsByID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        let keptIDs = Set(values.map(\.id))
        for record in records where !keptIDs.contains(record.id) {
            delete(record)
        }
        return values.enumerated().map { position, value in
            let record = recordsByID[value.id] ?? inserted(make())
            apply(record, value, position)
            return record
        }
    }

    private nonisolated func inserted<Record: PersistentModel>(_ record: Record) -> Record {
        insert(record)
        return record
    }
}

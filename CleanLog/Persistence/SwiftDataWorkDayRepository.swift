import Foundation
import SwiftData
import os

final class SwiftDataWorkDayRepository: WorkDayRepository {
    private let container: ModelContainer
    private let observers = StoreObservers()
    private let logger = Logger(subsystem: "CleanLog", category: "SwiftDataWorkDayRepository")

    init(container: ModelContainer) {
        self.container = container
    }

    func day(_ day: DayKey) -> AsyncStream<WorkDay> {
        observers.stream { [unowned self] in
            do {
                return try storedRecord(day)?.domain ?? .empty(day)
            } catch {
                logger.error("Could not read the day \(day.storageValue): \(error)")
                return .empty(day)
            }
        }
    }

    func days(in month: MonthKey) -> AsyncStream<[WorkDay]> {
        let first = month.firstDayStorageValue
        let last = month.lastDayStorageValue
        let descriptor = FetchDescriptor<WorkDayRecord>(
            predicate: #Predicate { $0.dayValue >= first && $0.dayValue <= last },
            sortBy: [SortDescriptor(\.dayValue)]
        )
        return observers.stream { [unowned self] in
            do {
                return try context.fetch(descriptor).map(\.domain)
            } catch {
                logger.error("Could not read the month \(first): \(error)")
                return []
            }
        }
    }

    func latestDayWithEntries(before day: DayKey) async throws -> WorkDay? {
        let value = day.storageValue
        let descriptor = FetchDescriptor<WorkDayRecord>(
            predicate: #Predicate { $0.dayValue < value },
            sortBy: [SortDescriptor(\.dayValue, order: .reverse)]
        )
        return try context.fetch(descriptor).lazy.map(\.domain).first { !$0.entries.isEmpty }
    }

    func update(_ day: DayKey, _ change: (WorkDay) throws -> WorkDay) async throws {
        let stored = try storedRecord(day)
        let changed = try change(stored?.domain ?? .empty(day))
        guard stored != nil || !changed.isBlank else { return }
        let record = stored ?? insertedRecord()
        record.apply(changed)
        try context.saveOrRollBack()
        observers.notify()
    }

    private var context: ModelContext {
        container.mainContext
    }

    private func storedRecord(_ day: DayKey) throws -> WorkDayRecord? {
        let value = day.storageValue
        let descriptor = FetchDescriptor<WorkDayRecord>(predicate: #Predicate { $0.dayValue == value })
        return try context.fetch(descriptor).first
    }

    private func insertedRecord() -> WorkDayRecord {
        let record = WorkDayRecord()
        context.insert(record)
        return record
    }
}

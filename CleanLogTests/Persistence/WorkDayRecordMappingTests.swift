import Foundation
import SwiftData
import Testing

@testable import CleanLog

struct WorkDayRecordMappingTests {
    private let container = ModelContainer.inMemory()
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")

    private var context: ModelContext {
        container.mainContext
    }

    private func recordedDay() -> WorkDay {
        var day = WorkDay.fixture(today, ticked: [a100], unticked: [a101])
        day.entries[0].cleanedAt = .warsaw(2026, 11, 13, 10)
        day.sessions = [
            WorkSession(
                id: UUID(),
                start: .warsaw(2026, 11, 13, 8),
                end: .warsaw(2026, 11, 13, 12)
            ),
            WorkSession(
                id: UUID(),
                start: .warsaw(2026, 11, 13, 13),
                end: nil
            ),
        ]
        day.manualDuration = .seconds(4 * 3600)
        day.isTimerFinished = true
        day.isTimeDropped = true
        return day
    }

    @Test
    func roundTripsEveryField() {
        let day = recordedDay()
        let record = context.inserted(WorkDayRecord())

        record.apply(day)

        #expect(record.domain == day)
    }

    @Test
    func syncsEntriesByID() throws {
        let record = context.inserted(WorkDayRecord())
        let day = recordedDay()
        record.apply(day)
        try context.save()

        var changed = day.removingEntry(day.entries[1].id).planning([.fixture("102")])
        changed.entries[0].isCleaned = false
        changed.entries[0].cleanedAt = nil
        record.apply(changed)
        try context.save()

        #expect(record.domain == changed)
        #expect(try context.fetchCount(FetchDescriptor<DayEntryRecord>()) == 2)
    }

    @Test
    func keepsOneRecordPerDay() async throws {
        let repository = SwiftDataWorkDayRepository(container: container)

        try await repository.update(today) { $0.planning([a100]) }
        try await repository.update(today) { $0.planning([a101]) }

        let records = try context.fetch(FetchDescriptor<WorkDayRecord>())
        #expect(records.map(\.dayValue) == [today.storageValue])
    }

    @Test
    func createsNoRecordForABlankDay() async throws {
        let repository = SwiftDataWorkDayRepository(container: container)

        try await repository.update(today) { $0 }

        #expect(try context.fetchCount(FetchDescriptor<WorkDayRecord>()) == 0)
    }
}

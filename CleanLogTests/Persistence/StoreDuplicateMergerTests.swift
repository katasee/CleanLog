import Foundation
import SwiftData
import Testing

@testable import CleanLog

struct StoreDuplicateMergerTests {
    private let container = ModelContainer.inMemory()
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let older = Apartment.copy(.fixture(1), name: "100", minorUnits: 2800)
    private let newer = Apartment.copy(.fixture(2), name: "100 ", minorUnits: 3000)

    private var context: ModelContext {
        container.mainContext
    }

    private var merger: StoreDuplicateMerger {
        StoreDuplicateMerger(container: container)
    }

    private func insert(_ apartment: Apartment, changedOn day: Int) {
        context.inserted(ApartmentRecord()).apply(Revision(value: apartment, changedAt: .warsaw(2026, 11, day)))
    }

    private func insert(_ workDay: WorkDay, changedAt hour: Int) {
        context.inserted(WorkDayRecord()).apply(Revision(value: workDay, changedAt: .warsaw(2026, 11, 13, hour)))
    }

    private func storedApartments() throws -> [Apartment] {
        try context.fetch(FetchDescriptor<ApartmentRecord>()).map(\.domain)
    }

    private func storedDays() throws -> [WorkDay] {
        try context.fetch(FetchDescriptor<WorkDayRecord>()).map(\.domain)
    }

    @Test
    func mergesTwoApartmentsWithTheSameName() throws {
        insert(older, changedOn: 2)
        insert(newer, changedOn: 5)

        let saved = try merger.mergeDuplicates()

        #expect(saved)
        #expect(try storedApartments().map(\.id) == [older.id])
        #expect(try storedApartments().map(\.price) == [Money(minorUnits: 3000)])
    }

    @Test
    func repointsEntriesOfRemovedCopies() throws {
        insert(older, changedOn: 2)
        insert(newer, changedOn: 5)
        insert(.empty(DayKey(year: 2026, month: 11, day: 3)).planning([newer]), changedAt: 9)

        _ = try merger.mergeDuplicates()

        #expect(try storedDays().flatMap(\.entries).map(\.apartmentID) == [older.id])
    }

    @Test
    func mergesTwoCopiesOfADay() throws {
        insert(.empty(today).planning([.fixture("100")]), changedAt: 9)
        insert(.empty(today).planning([.fixture("101")]), changedAt: 10)

        let saved = try merger.mergeDuplicates()

        #expect(saved)
        #expect(try storedDays().map(\.day) == [today])
        #expect(try storedDays().flatMap(\.entries).map(\.name) == ["101", "100"])
    }

    @Test
    func unitesEntriesThatBecameTheSameApartment() throws {
        insert(older, changedOn: 2)
        insert(newer, changedOn: 5)
        insert(.empty(today).planning([older, newer]), changedAt: 9)

        _ = try merger.mergeDuplicates()

        #expect(try storedDays().flatMap(\.entries).map(\.apartmentID) == [older.id])
        #expect(try context.fetchCount(FetchDescriptor<DayEntryRecord>()) == 1)
    }

    @Test
    func aCleanStoreIsNotSaved() throws {
        insert(.fixture("100"), changedOn: 2)
        insert(.fixture("101"), changedOn: 2)
        insert(.empty(today).planning([.fixture("100")]), changedAt: 9)
        try context.save()

        #expect(try merger.mergeDuplicates() == false)
    }

    @Test
    func aSecondPassFindsNothing() throws {
        insert(older, changedOn: 2)
        insert(newer, changedOn: 5)
        insert(.empty(today).planning([older]), changedAt: 9)
        insert(.empty(today).planning([newer]), changedAt: 10)
        _ = try merger.mergeDuplicates()

        #expect(try merger.mergeDuplicates() == false)
    }
}

extension Apartment {
    fileprivate static func copy(_ id: UUID, name: String, minorUnits: Int) -> Apartment {
        Apartment(
            id: id,
            name: name,
            price: Money(minorUnits: minorUnits),
            accessCode: nil,
            isReportedSeparately: false,
            createdAt: .warsaw(2026, 11, 1)
        )
    }
}

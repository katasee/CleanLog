import Foundation
import SwiftData
import Testing

@testable import CleanLog

struct ChangeStampTests {
    private let container = ModelContainer.inMemory()
    private let clock = TestClock(.warsaw(2026, 11, 13, 9))
    private let today = DayKey(year: 2026, month: 11, day: 13)

    private var apartments: SwiftDataApartmentRepository {
        SwiftDataApartmentRepository(container: container) { [clock] in clock.now }
    }

    private var workDays: SwiftDataWorkDayRepository {
        SwiftDataWorkDayRepository(container: container) { [clock] in clock.now }
    }

    @Test
    func addStampsTheApartment() async throws {
        _ = try await apartments.add(ApartmentDraft(.fixture("100")))

        let records = try container.mainContext.fetch(FetchDescriptor<ApartmentRecord>())
        #expect(records.map(\.changedAt) == [.warsaw(2026, 11, 13, 9)])
    }

    @Test
    func updateStampsTheApartment() async throws {
        var apartment = try await apartments.add(ApartmentDraft(.fixture("100")))
        clock.now = .warsaw(2026, 11, 13, 10)
        apartment.price = Money(minorUnits: 3000)

        try await apartments.update(apartment)

        let records = try container.mainContext.fetch(FetchDescriptor<ApartmentRecord>())
        #expect(records.map(\.changedAt) == [.warsaw(2026, 11, 13, 10)])
    }

    @Test
    func aDayUpdateStampsTheDay() async throws {
        clock.now = .warsaw(2026, 11, 13, 11)

        try await workDays.update(today) { $0.planning([.fixture("100")]) }

        let records = try container.mainContext.fetch(FetchDescriptor<WorkDayRecord>())
        #expect(records.map(\.changedAt) == [.warsaw(2026, 11, 13, 11)])
    }
}

import Foundation
import SwiftData
import Testing

@testable import CleanLog

struct ApartmentRecordMappingTests {
    private let container = ModelContainer.inMemory()

    @Test
    func roundTripsEveryField() {
        let apartment = Apartment(
            id: UUID(),
            name: "101",
            price: Money(minorUnits: 3550),
            accessCode: "4821",
            isReportedSeparately: true,
            createdAt: .warsaw(2026, 11, 1, 9)
        )
        let record = container.mainContext.inserted(ApartmentRecord())

        record.apply(apartment)

        #expect(record.domain == apartment)
    }

    @Test
    func revisionCarriesChangedAt() {
        let revision = Revision(value: Apartment.fixture("100"), changedAt: .warsaw(2026, 11, 13, 9))
        let record = container.mainContext.inserted(ApartmentRecord())

        record.apply(revision)

        #expect(record.revision == revision)
    }
}

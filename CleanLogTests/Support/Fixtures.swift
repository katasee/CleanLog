import Foundation

@testable import CleanLog

extension Apartment {
    static func fixture(
        _ name: String,
        minorUnits: Int = 2800,
        separate: Bool = false,
        sortOrder: Int = 0,
        archived: Bool = false
    ) -> Apartment {
        Apartment(
            id: UUID(),
            name: name,
            price: Money(minorUnits: minorUnits),
            accessCode: nil,
            isReportedSeparately: separate,
            sortOrder: sortOrder,
            isArchived: archived,
            createdAt: .warsaw(2026, 11, 1)
        )
    }
}

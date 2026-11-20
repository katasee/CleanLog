import Foundation

@testable import CleanLog

extension Apartment {
    static func fixture(
        _ name: String,
        grosze: Int = 2800,
        separate: Bool = false,
        sortOrder: Int = 0,
        archived: Bool = false,
        accessCode: String? = nil
    ) -> Apartment {
        Apartment(
            id: UUID(),
            name: name,
            price: Money(grosze: grosze),
            accessCode: accessCode,
            isReportedSeparately: separate,
            sortOrder: sortOrder,
            isArchived: archived,
            createdAt: .warsaw(2026, 11, 1)
        )
    }
}

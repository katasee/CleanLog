import Foundation

extension ApartmentRecord {
    var domain: Apartment {
        Apartment(
            id: id,
            name: name,
            price: Money(minorUnits: priceMinorUnits),
            accessCode: accessCode,
            isReportedSeparately: isReportedSeparately,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: createdAt
        )
    }

    func apply(_ apartment: Apartment) {
        id = apartment.id
        name = apartment.name
        priceMinorUnits = apartment.price.minorUnits
        accessCode = apartment.accessCode
        isReportedSeparately = apartment.isReportedSeparately
        sortOrder = apartment.sortOrder
        isArchived = apartment.isArchived
        createdAt = apartment.createdAt
    }
}

import Foundation

extension ApartmentRecord {
    var domain: Apartment {
        Apartment(
            id: id,
            name: name,
            price: Money(minorUnits: priceMinorUnits),
            accessCode: accessCode,
            isReportedSeparately: isReportedSeparately,
            createdAt: createdAt
        )
    }

    func apply(_ apartment: Apartment) {
        id = apartment.id
        name = apartment.name
        priceMinorUnits = apartment.price.minorUnits
        accessCode = apartment.accessCode
        isReportedSeparately = apartment.isReportedSeparately
        createdAt = apartment.createdAt
    }
}

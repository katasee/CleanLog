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

    var revision: Revision<Apartment> {
        Revision(value: domain, changedAt: changedAt)
    }

    func apply(_ revision: Revision<Apartment>) {
        apply(revision.value)
        changedAt = revision.changedAt
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

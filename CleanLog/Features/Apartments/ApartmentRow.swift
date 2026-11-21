import Foundation

struct ApartmentRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let priceText: String
    let isReportedSeparately: Bool
}

extension ApartmentRow {
    init(_ apartment: Apartment, locale: Locale) {
        self.init(
            id: apartment.id,
            name: apartment.name,
            priceText: MoneyFormat.string(apartment.price, locale: locale),
            isReportedSeparately: apartment.isReportedSeparately
        )
    }
}

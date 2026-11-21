#if DEBUG
    import Foundation

    enum ApartmentsPreviewData {
        private static let regularNames = ["54", "64", "96", "100", "105", "115", "116", "138", "6piw", "133kol"]
        private static let regularPrice = Money(minorUnits: 2800)
        private static let separatePrice = Money(minorUnits: 5600)

        static let template: [Apartment] =
            regularNames.map { apartment($0, price: regularPrice, isReportedSeparately: false) }
            + [apartment("155", price: separatePrice, isReportedSeparately: true)]

        private static func apartment(
            _ name: String,
            price: Money,
            isReportedSeparately: Bool
        ) -> Apartment {
            Apartment(
                id: UUID(),
                name: name,
                price: price,
                accessCode: nil,
                isReportedSeparately: isReportedSeparately,
                createdAt: .now
            )
        }
    }
#endif

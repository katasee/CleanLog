import Foundation

nonisolated struct DayEntry: Sendable, Hashable, Identifiable {
    let id: UUID
    let apartmentID: UUID
    let name: String
    let price: Money
    let isReportedSeparately: Bool
    var isCleaned: Bool
    var cleanedAt: Date?
}

extension DayEntry {
    nonisolated init(planning apartment: Apartment) {
        self.init(
            id: UUID(),
            apartmentID: apartment.id,
            name: apartment.name,
            price: apartment.price,
            isReportedSeparately: apartment.isReportedSeparately,
            isCleaned: false,
            cleanedAt: nil
        )
    }

    nonisolated func pointing(to apartmentID: UUID) -> DayEntry {
        DayEntry(
            id: id,
            apartmentID: apartmentID,
            name: name,
            price: price,
            isReportedSeparately: isReportedSeparately,
            isCleaned: isCleaned,
            cleanedAt: cleanedAt
        )
    }
}

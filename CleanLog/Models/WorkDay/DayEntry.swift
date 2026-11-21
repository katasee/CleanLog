import Foundation

nonisolated struct DayEntry: Sendable, Hashable, Identifiable {
    let id: UUID
    let apartmentID: UUID
    let name: String
    let price: Money
    let isReportedSeparately: Bool
    let sortOrder: Int
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
            sortOrder: apartment.sortOrder,
            isCleaned: false,
            cleanedAt: nil
        )
    }

    nonisolated func replanned() -> DayEntry {
        DayEntry(
            id: UUID(),
            apartmentID: apartmentID,
            name: name,
            price: price,
            isReportedSeparately: isReportedSeparately,
            sortOrder: sortOrder,
            isCleaned: false,
            cleanedAt: nil
        )
    }
}

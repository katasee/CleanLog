import Foundation

nonisolated struct Apartment: Sendable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var price: Money
    var accessCode: String?
    var isReportedSeparately: Bool
    let createdAt: Date
}

extension Apartment {
    nonisolated init(_ draft: ApartmentDraft, createdAt: Date) {
        self.init(
            id: UUID(),
            name: draft.name,
            price: draft.price,
            accessCode: draft.accessCode,
            isReportedSeparately: draft.isReportedSeparately,
            createdAt: createdAt
        )
    }

    nonisolated func applying(_ draft: ApartmentDraft) -> Apartment {
        var copy = self
        copy.name = draft.name
        copy.price = draft.price
        copy.accessCode = draft.accessCode
        copy.isReportedSeparately = draft.isReportedSeparately
        return copy
    }
}

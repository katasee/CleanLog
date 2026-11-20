import Foundation

nonisolated enum ApartmentError: Error, Equatable {
    case emptyName
    case duplicateName
    case negativePrice
    case notFound
}

/// The editable fields of an apartment, validated the same way by the form, the fakes and the store.
nonisolated struct ApartmentDraft: Sendable, Hashable {
    var name: String
    var price: Money
    var accessCode: String?
    var isReportedSeparately: Bool

    init(name: String, price: Money, accessCode: String?, isReportedSeparately: Bool) {
        self.name = name
        self.price = price
        self.accessCode = accessCode
        self.isReportedSeparately = isReportedSeparately
    }

    init(_ apartment: Apartment) {
        self.init(
            name: apartment.name,
            price: apartment.price,
            accessCode: apartment.accessCode,
            isReportedSeparately: apartment.isReportedSeparately
        )
    }

    /// Returns the draft normalized for storage: the name and code trimmed, a blank code `nil`.
    /// A name may repeat only the name of an archived apartment, or of the one being edited (`excluding`).
    func validated(
        against existing: [Apartment],
        excluding id: UUID? = nil
    ) throws(ApartmentError) -> ApartmentDraft {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw .emptyName }
        guard price >= .zero else { throw .negativePrice }

        let isTaken = existing.contains { apartment in
            !apartment.isArchived
                && apartment.id != id
                && apartment.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
        guard !isTaken else { throw .duplicateName }

        let trimmedCode = accessCode?.trimmingCharacters(in: .whitespacesAndNewlines)
        return ApartmentDraft(
            name: trimmedName,
            price: price,
            accessCode: trimmedCode?.isEmpty == false ? trimmedCode : nil,
            isReportedSeparately: isReportedSeparately
        )
    }
}

import Foundation

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

    func validated(
        against existing: [Apartment],
        excluding id: UUID? = nil
    ) throws(ApartmentError) -> ApartmentDraft {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw .emptyName }
        guard price >= .zero else { throw .negativePrice }
        guard !Self.isName(trimmedName, takenIn: existing, excluding: id) else { throw .duplicateName }
        return ApartmentDraft(
            name: trimmedName,
            price: price,
            accessCode: normalizedAccessCode,
            isReportedSeparately: isReportedSeparately
        )
    }

    private var normalizedAccessCode: String? {
        guard let trimmed = accessCode?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func isName(_ name: String, takenIn existing: [Apartment], excluding id: UUID?) -> Bool {
        existing.contains { apartment in
            !apartment.isArchived
                && apartment.id != id
                && apartment.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }
}

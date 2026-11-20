import Foundation

/// An apartment in the cleaner's template.
nonisolated struct Apartment: Sendable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var price: Money
    /// The door or key-box code; permanent per apartment.
    var accessCode: String?
    /// Listed after the count in the report (`=7+155`) instead of inside the brackets.
    var isReportedSeparately: Bool
    var sortOrder: Int
    var isArchived: Bool
    let createdAt: Date
}

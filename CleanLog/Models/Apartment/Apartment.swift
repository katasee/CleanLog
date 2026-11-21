import Foundation

nonisolated struct Apartment: Sendable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var price: Money
    var accessCode: String?
    var isReportedSeparately: Bool
    var sortOrder: Int
    var isArchived: Bool
    let createdAt: Date
}

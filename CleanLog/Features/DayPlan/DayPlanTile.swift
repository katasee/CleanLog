import Foundation

struct DayPlanTile: Identifiable, Equatable {
    let id: UUID
    let name: String
    let priceText: String
    let isSelected: Bool
}

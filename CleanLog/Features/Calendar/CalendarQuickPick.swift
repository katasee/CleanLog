import Foundation

struct CalendarQuickPick: Identifiable, Equatable {
    let day: DayKey
    let title: String
    let isSelected: Bool

    var id: DayKey {
        day
    }
}

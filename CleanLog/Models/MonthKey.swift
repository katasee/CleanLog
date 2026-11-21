import Foundation

nonisolated struct MonthKey: Sendable, Hashable, Comparable, Codable {
    let year: Int
    let month: Int

    var previous: MonthKey {
        month == 1 ? MonthKey(year: year - 1, month: 12) : MonthKey(year: year, month: month - 1)
    }

    var next: MonthKey {
        month == 12 ? MonthKey(year: year + 1, month: 1) : MonthKey(year: year, month: month + 1)
    }

    var firstDayStorageValue: Int {
        DayKey(year: year, month: month, day: 1).storageValue
    }

    var lastDayStorageValue: Int {
        DayKey(year: year, month: month, day: 31).storageValue
    }

    func contains(_ day: DayKey) -> Bool {
        day.year == year && day.month == month
    }

    func days(in calendar: Calendar) -> [DayKey] {
        let first = DayKey(year: year, month: month, day: 1)
        guard let range = calendar.range(of: .day, in: .month, for: first.startDate(in: calendar)) else {
            preconditionFailure("Invalid month \(self)")
        }
        return range.map { DayKey(year: year, month: month, day: $0) }
    }

    static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

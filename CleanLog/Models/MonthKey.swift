import Foundation

/// A calendar month, independent of time zone.
nonisolated struct MonthKey: Sendable, Hashable, Comparable, Codable {
    let year: Int
    let month: Int

    var previous: MonthKey {
        month == 1 ? MonthKey(year: year - 1, month: 12) : MonthKey(year: year, month: month - 1)
    }

    var next: MonthKey {
        month == 12 ? MonthKey(year: year + 1, month: 1) : MonthKey(year: year, month: month + 1)
    }

    /// The lowest `DayKey.storageValue` in the month.
    var firstDayStorageValue: Int {
        year * 10_000 + month * 100 + 1
    }

    /// An upper bound for every `DayKey.storageValue` in the month (day 31, whether or not it exists).
    var lastDayStorageValue: Int {
        year * 10_000 + month * 100 + 31
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

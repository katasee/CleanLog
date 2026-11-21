import Foundation

nonisolated struct DayKey: Sendable, Hashable, Comparable, Codable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            preconditionFailure("No day components for \(date)")
        }
        self.init(year: year, month: month, day: day)
    }

    init?(storageValue: Int) {
        let year = storageValue / 10_000
        let month = storageValue / 100 % 100
        let day = storageValue % 100
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        self.init(year: year, month: month, day: day)
    }

    var storageValue: Int {
        year * 10_000 + month * 100 + day
    }

    var monthKey: MonthKey {
        MonthKey(year: year, month: month)
    }

    func startDate(in calendar: Calendar) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else {
            preconditionFailure("Invalid day \(self)")
        }
        return date
    }

    func adding(days: Int, calendar: Calendar) -> DayKey {
        guard let date = calendar.date(byAdding: .day, value: days, to: startDate(in: calendar)) else {
            preconditionFailure("Cannot add \(days) days to \(self)")
        }
        return DayKey(date, calendar: calendar)
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        lhs.storageValue < rhs.storageValue
    }
}

import Foundation

struct TodaySelection: Hashable {
    private(set) var today: DayKey
    private(set) var day: DayKey

    init(today: DayKey) {
        self.today = today
        day = today
    }

    var isShowingToday: Bool {
        day == today
    }

    mutating func step(by days: Int, calendar: Calendar) {
        day = day.adding(days: days, calendar: calendar)
    }

    mutating func show(_ day: DayKey) {
        self.day = day
    }

    mutating func showToday() {
        day = today
    }

    mutating func advance(to newToday: DayKey) {
        if isShowingToday {
            day = newToday
        }
        today = newToday
    }

    static func timeUntilNextDay(after now: Date, calendar: Calendar) -> Duration {
        guard let nextDay = calendar.dateInterval(of: .day, for: now)?.end else {
            preconditionFailure("No day contains \(now)")
        }
        return .seconds(nextDay.timeIntervalSince(now))
    }
}

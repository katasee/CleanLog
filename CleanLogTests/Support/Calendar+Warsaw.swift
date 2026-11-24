import Foundation

extension Calendar {
    static let warsaw: Calendar = {
        guard let timeZone = TimeZone(identifier: "Europe/Warsaw") else {
            preconditionFailure("Europe/Warsaw time zone is missing")
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    static let mondayFirst = warsaw.startingWeeks(on: 2)
    static let sundayFirst = warsaw.startingWeeks(on: 1)

    private func startingWeeks(on firstWeekday: Int) -> Calendar {
        var calendar = self
        calendar.firstWeekday = firstWeekday
        return calendar
    }
}

extension Date {
    static func warsaw(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        guard let date = Calendar.warsaw.date(from: components) else {
            preconditionFailure("Invalid fixture date \(components)")
        }
        return date
    }
}

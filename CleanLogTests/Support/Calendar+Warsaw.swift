import Foundation

extension Calendar {
    /// The calendar every test pins: Gregorian, Warsaw time, POSIX locale.
    static let warsaw: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone = TimeZone(identifier: "Europe/Warsaw") {
            calendar.timeZone = timeZone
        }
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()
}

extension Date {
    /// A wall-clock moment in Warsaw, for readable test fixtures.
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

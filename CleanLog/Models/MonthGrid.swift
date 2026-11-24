import Foundation

nonisolated enum MonthGrid {
    private static let daysPerWeek = 7

    static func weeks(of month: MonthKey, calendar: Calendar) -> [[DayKey?]] {
        let days = month.days(in: calendar)
        guard let first = days.first else { return [] }
        let leading = blanks(leadingBlankCount(before: first, calendar: calendar))
        let cells = leading + days.map(Optional.some)
        let padded = cells + blanks((daysPerWeek - cells.count % daysPerWeek) % daysPerWeek)
        return stride(from: 0, to: padded.count, by: daysPerWeek).map { Array(padded[$0..<$0 + daysPerWeek]) }
    }

    private static func leadingBlankCount(before first: DayKey, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: first.startDate(in: calendar))
        return (weekday - calendar.firstWeekday + daysPerWeek) % daysPerWeek
    }

    private static func blanks(_ count: Int) -> [DayKey?] {
        Array(repeating: nil, count: count)
    }
}

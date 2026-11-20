import Foundation

/// The monthly report in the boss's fixed format: one line per worked day,
/// `13.11-(100,101,102)=3+106`, weeks separated by a blank line. Nothing here follows the device
/// locale — weeks always start on Monday.
nonisolated enum ReportBuilder {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    static func report(for month: MonthKey, days: [WorkDay]) -> String {
        let worked =
            days
            .filter { month.contains($0.day) && $0.hasCleanedEntries }
            .sorted { $0.day < $1.day }
        let weeks = Dictionary(grouping: worked, by: weekStart)
        return weeks.keys.sorted()
            .map { week in (weeks[week] ?? []).map(line).joined(separator: "\n") }
            .joined(separator: "\n\n")
    }

    /// `2.10-(54,64,96,105,115,138,6piw)=7+155`
    private static func line(for day: WorkDay) -> String {
        let cleaned = day.entries
            .filter(\.isCleaned)
            .sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
        let counted = cleaned.filter { !$0.isReportedSeparately }.map(\.name)
        let separate = cleaned.filter(\.isReportedSeparately).map { "+\($0.name)" }
        return "\(day.day.day).\(day.day.month)-(\(counted.joined(separator: ",")))=\(counted.count)"
            + separate.joined()
    }

    /// The Monday of the day's week.
    private static func weekStart(of day: WorkDay) -> DayKey {
        let date = day.day.startDate(in: calendar)
        let daysSinceMonday = (calendar.component(.weekday, from: date) + 5) % 7
        return day.day.adding(days: -daysSinceMonday, calendar: calendar)
    }
}

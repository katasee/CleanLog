import Foundation

nonisolated enum ReportBuilder {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = .gmt
        return calendar
    }()

    static func report(for month: MonthKey, days: [WorkDay]) -> String {
        weeks(of: workedDays(in: month, from: days))
            .map { week in week.map(line).joined(separator: "\n") }
            .joined(separator: "\n\n")
    }

    private static func workedDays(in month: MonthKey, from days: [WorkDay]) -> [WorkDay] {
        days
            .filter { month.contains($0.day) && $0.hasCleanedEntries }
            .sorted { $0.day < $1.day }
    }

    private static func weeks(of days: [WorkDay]) -> [[WorkDay]] {
        Dictionary(grouping: days) { weekStart(of: $0.day) }
            .sorted { $0.key < $1.key }
            .map(\.value)
    }

    private static func weekStart(of day: DayKey) -> DayKey {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: day.startDate(in: calendar)) else {
            preconditionFailure("No week for \(day)")
        }
        return DayKey(week.start, calendar: calendar)
    }

    private static func line(for day: WorkDay) -> String {
        let cleaned = ApartmentNameOrder.sorted(day.entries.filter(\.isCleaned), by: \.name)
        let counted = cleaned.filter { !$0.isReportedSeparately }.map(\.name)
        let separate = cleaned.filter(\.isReportedSeparately).map { "+\($0.name)" }
        return "\(date(of: day.day))-(\(counted.joined(separator: ",")))=\(counted.count)" + separate.joined()
    }

    private static func date(of day: DayKey) -> String {
        "\(day.day).\(day.month)"
    }
}

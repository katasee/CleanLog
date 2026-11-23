import Foundation

struct TodaySummary: Equatable {
    let earned: String
    let planned: String
    let progress: Double
    let month: String
    let monthEarned: String
    let monthCount: String
}

enum DaySummary: Equatable {
    case today(TodaySummary)
    case past(earned: String)
    case future(planned: String)
}

extension DaySummary {
    init(
        _ workDay: WorkDay,
        kind: DayKind,
        month: [WorkDay],
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) {
        let earned = MoneyFormat.string(workDay.earned, locale: locale)
        let planned = MoneyFormat.string(workDay.planned, locale: locale)
        switch kind {
        case .today:
            let stats = MonthStats.calculate(days: month, now: now)
            self = .today(
                TodaySummary(
                    earned: earned,
                    planned: String(localized: .todaySummaryPlanned(planned), locale: locale),
                    progress: Self.progress(of: workDay),
                    month: DayFormat.month(workDay.day.monthKey, calendar: calendar, locale: locale),
                    monthEarned: MoneyFormat.string(stats.earned, locale: locale),
                    monthCount: String(localized: .todaySummaryMonthCount(stats.cleanedCount), locale: locale)
                )
            )
        case .past:
            self = .past(earned: earned)
        case .future:
            self = .future(planned: planned)
        }
    }

    private static func progress(of workDay: WorkDay) -> Double {
        guard workDay.planned.minorUnits > 0 else { return 0 }
        return Double(workDay.earned.minorUnits) / Double(workDay.planned.minorUnits)
    }
}

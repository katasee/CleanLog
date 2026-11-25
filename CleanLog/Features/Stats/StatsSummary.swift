import Foundation

struct StatsApartmentRow: Equatable, Identifiable {
    let id: UUID
    let name: String
    let countText: String
    let barFraction: Double
}

struct StatsSummary: Equatable {
    let earnedText: String
    let changeText: String?
    let cleanedText: String
    let workedText: String
    let perHourText: String
    let perDayText: String
    let workingDaysText: String
    let topApartments: [StatsApartmentRow]

    var hasCleanedApartments: Bool {
        !topApartments.isEmpty
    }
}

extension StatsSummary {
    init(
        stats: MonthStats,
        previousEarned: Money?,
        month: MonthKey,
        isFinished: Bool,
        calendar: Calendar,
        locale: Locale
    ) {
        let previousMonth = DayFormat.monthInPhrase(month.previous, calendar: calendar, locale: locale)
        self.init(
            earnedText: MoneyFormat.string(stats.earned, locale: locale),
            changeText: isFinished
                ? Self.change(from: previousEarned, to: stats.earned, previousMonth: previousMonth, locale: locale)
                : nil,
            cleanedText: CountFormat.string(stats.cleanedCount, locale: locale),
            workedText: DurationFormat.hoursAndMinutes(stats.workedDuration, locale: locale),
            perHourText: Self.amount(stats.earningsPerHour, locale: locale),
            perDayText: Self.amount(stats.averagePerWorkingDay, locale: locale),
            workingDaysText: String(localized: .statsTopWorkingDays(stats.workingDays), locale: locale),
            topApartments: Self.rows(for: stats.topApartments, locale: locale)
        )
    }

    private static func change(
        from previousEarned: Money?,
        to earned: Money,
        previousMonth: String,
        locale: Locale
    ) -> String? {
        guard let previousEarned, let change = EarningsChange.between(current: earned, previous: previousEarned) else {
            return nil
        }
        switch change.direction {
        case .up:
            return String(localized: .statsChangeUp(change.percent, previousMonth), locale: locale)
        case .down:
            return String(localized: .statsChangeDown(change.percent, previousMonth), locale: locale)
        case .same:
            return String(localized: .statsChangeSame(previousMonth), locale: locale)
        }
    }

    private static func amount(_ money: Money?, locale: Locale) -> String {
        guard let money else { return String(localized: .statsValueNone, locale: locale) }
        return MoneyFormat.string(money, locale: locale)
    }

    private static func rows(for apartments: [ApartmentCount], locale: Locale) -> [StatsApartmentRow] {
        guard let highest = apartments.first?.count, highest > 0 else { return [] }
        return apartments.map { apartment in
            StatsApartmentRow(
                id: apartment.apartmentID,
                name: apartment.name,
                countText: String(localized: .statsTopCount(apartment.count), locale: locale),
                barFraction: Double(apartment.count) / Double(highest)
            )
        }
    }
}

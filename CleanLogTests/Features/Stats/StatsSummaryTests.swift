import Foundation
import Testing

@testable import CleanLog

struct StatsSummaryTests {
    private let ukrainian = Locale(identifier: "uk_UA")
    private let november = MonthKey(year: 2026, month: 11)
    private let topIDs = [UUID(), UUID(), UUID()]

    private func stats(
        earned: Int = 201_600,
        workingDays: Int = 12,
        topCounts: [Int] = [10, 10, 9]
    ) -> MonthStats {
        MonthStats(
            earned: Money(minorUnits: earned),
            cleanedCount: 63,
            workingDays: workingDays,
            workedDuration: .seconds(62 * 3600 + 15 * 60),
            earningsPerHour: Money(minorUnits: 3300),
            averagePerWorkingDay: Money(minorUnits: 16_800),
            topApartments: zip(topIDs, zip(["100", "102", "101"], topCounts)).map { id, nameAndCount in
                ApartmentCount(apartmentID: id, name: nameAndCount.0, count: nameAndCount.1)
            }
        )
    }

    private func summary(
        _ stats: MonthStats,
        previousEarned: Int? = 185_000,
        month: MonthKey? = nil,
        isFinished: Bool = true,
        locale: Locale? = nil
    ) -> StatsSummary {
        StatsSummary(
            stats: stats,
            previousEarned: previousEarned.map { Money(minorUnits: $0) },
            month: month ?? november,
            isFinished: isFinished,
            calendar: .warsaw,
            locale: locale ?? ukrainian
        )
    }

    @Test func formatsAFinishedMonth() {
        let summary = summary(stats())

        #expect(summary.earnedText == "2\u{00A0}016\u{00A0}zł")
        #expect(summary.changeText == "↑ 9% до жовтня")
        #expect(summary.cleanedText == "63")
        #expect(summary.workedText == "62 год, 15 хв")
        #expect(summary.perHourText == "33\u{00A0}zł")
        #expect(summary.perDayText == "168\u{00A0}zł")
        #expect(summary.workingDaysText == "12 робочих днів")
        #expect(summary.topApartments.map(\.id) == topIDs)
        #expect(summary.topApartments.map(\.name) == ["100", "102", "101"])
        #expect(summary.topApartments.map(\.countText) == ["10 разів", "10 разів", "9 разів"])
        #expect(summary.topApartments.map(\.barFraction) == [1, 1, 0.9])
        #expect(summary.hasCleanedApartments)
    }

    @Test func showsADropAndNoChange() {
        #expect(summary(stats(earned: 150_000), previousEarned: 170_000).changeText == "↓ 12% до жовтня")
        #expect(summary(stats(earned: 100_000), previousEarned: 100_000).changeText == "0% до жовтня")
    }

    @Test func hidesTheChangeOnTheCurrentMonth() {
        #expect(summary(stats(), isFinished: false).changeText == nil)
    }

    @Test func hidesTheChangeUntilThePreviousMonthArrives() {
        #expect(summary(stats(), previousEarned: nil).changeText == nil)
    }

    @Test func hidesTheChangeWhenTheMonthEarnedNothing() {
        let empty = MonthStats.calculate(days: [], today: DayKey(year: 2026, month: 12, day: 1))
        let summary = summary(empty, previousEarned: 100_000)

        #expect(summary.changeText == nil)
        #expect(summary.earnedText == "0\u{00A0}zł")
        #expect(summary.cleanedText == "0")
        #expect(summary.workedText == "0 год")
        #expect(summary.perHourText == "—")
        #expect(summary.perDayText == "—")
        #expect(!summary.hasCleanedApartments)
    }

    @Test func namesTheMonthBeforeJanuary() {
        let changeText = summary(stats(), month: MonthKey(year: 2027, month: 1)).changeText

        #expect(changeText?.hasSuffix("до грудня") == true)
    }

    @Test func pluralizesCounts() {
        #expect(summary(stats(workingDays: 1)).workingDaysText == "1 робочий день")
        #expect(summary(stats(workingDays: 3)).workingDaysText == "3 робочі дні")
        #expect(summary(stats(workingDays: 5)).workingDaysText == "5 робочих днів")
        #expect(summary(stats(topCounts: [3, 2, 1])).topApartments.last?.countText == "1 раз")
    }

    @Test func formatsInEnglish() {
        #expect(summary(stats(), locale: Locale(identifier: "en_US")).changeText == "↑ 9% vs October")
    }
}

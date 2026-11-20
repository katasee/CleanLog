import Foundation
import Testing

@testable import CleanLog

struct ReportBuilderTests {
    private let october = MonthKey(year: 2026, month: 10)
    private let november = MonthKey(year: 2026, month: 11)

    private func day(_ key: DayKey, ticked: [Apartment], unticked: [Apartment] = []) -> WorkDay {
        var day = WorkDay.empty(key).planning(ticked + unticked)
        for index in day.entries.indices where ticked.contains(where: { $0.id == day.entries[index].apartmentID }) {
            day.entries[index].isCleaned = true
        }
        return day
    }

    @Test func reproducesTheOctoberReport() {
        #expect(ReportBuilder.report(for: october, days: OctoberReport.days) == OctoberReport.expected)
    }

    @Test func ignoresDaysOfOtherMonths() {
        let a54 = OctoberReport.template[0]
        let neighbours = [
            day(DayKey(year: 2026, month: 9, day: 30), ticked: [a54]),
            day(DayKey(year: 2026, month: 11, day: 1), ticked: [a54]),
        ]
        #expect(ReportBuilder.report(for: october, days: neighbours + OctoberReport.days) == OctoberReport.expected)
    }

    @Test func omitsDaysWithNothingTicked() {
        let untickedOnly = day(DayKey(year: 2026, month: 11, day: 3), ticked: [], unticked: [.fixture("100")])
        #expect(ReportBuilder.report(for: november, days: [untickedOnly]).isEmpty)
        #expect(ReportBuilder.report(for: november, days: []).isEmpty)
    }

    @Test func printsADayWithOnlySeparateApartments() {
        let only155 = day(DayKey(year: 2026, month: 11, day: 5), ticked: [.fixture("155", separate: true)])
        #expect(ReportBuilder.report(for: november, days: [only155]) == "5.11-()=0+155")
    }

    @Test func listsSeparateApartmentsInTemplateOrder() {
        let mixed = day(
            DayKey(year: 2026, month: 11, day: 5),
            ticked: [
                .fixture("160", separate: true, sortOrder: 9),
                .fixture("101", sortOrder: 1),
                .fixture("155", separate: true, sortOrder: 8),
                .fixture("100", sortOrder: 0),
                .fixture("102", sortOrder: 2),
            ]
        )
        #expect(ReportBuilder.report(for: november, days: [mixed]) == "5.11-(100,101,102)=3+155+160")
    }

    @Test func startsWeeksOnMonday() {
        let a100 = Apartment.fixture("100")
        let monday = day(DayKey(year: 2026, month: 11, day: 2), ticked: [a100])
        let sunday = day(DayKey(year: 2026, month: 11, day: 1), ticked: [a100])
        let report = ReportBuilder.report(for: november, days: [monday, sunday])
        #expect(report == "1.11-(100)=1\n\n2.11-(100)=1")
    }
}

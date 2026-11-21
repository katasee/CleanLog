import Foundation
import Testing

@testable import CleanLog

struct MonthStatsTests {
    private let now = Date.warsaw(2026, 11, 30, 20)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")
    private let a102 = Apartment.fixture("102")
    private let a103 = Apartment.fixture("103")
    private let a106 = Apartment.fixture("106", minorUnits: 5600, separate: true)

    private func day(
        _ number: Int,
        _ apartments: [Apartment],
        ticked: Set<String>,
        hours: Int = 0,
        manualHours: Int? = nil
    ) -> WorkDay {
        var day = WorkDay.empty(DayKey(year: 2026, month: 11, day: number)).planning(apartments)
        for index in day.entries.indices where ticked.contains(day.entries[index].name) {
            day.entries[index].isCleaned = true
            day.entries[index].cleanedAt = .warsaw(2026, 11, number, 12)
        }
        if hours > 0 {
            let start = Date.warsaw(2026, 11, number, 8)
            day.sessions = [
                WorkSession(
                    id: UUID(),
                    start: start,
                    end: start.addingTimeInterval(Double(hours) * 3600)
                )
            ]
        }
        day.manualDuration = manualHours.map { .seconds($0 * 3600) }
        return day
    }

    @Test func isEmptyForNoDays() {
        let stats = MonthStats.calculate(days: [], now: now)
        #expect(stats.earned == .zero)
        #expect(stats.cleanedCount == 0)
        #expect(stats.workingDays == 0)
        #expect(stats.workedDuration == .zero)
        #expect(stats.earningsPerHour == nil)
        #expect(stats.averagePerWorkingDay == nil)
        #expect(stats.topApartments.isEmpty)
    }

    @Test func totalsAMonth() {
        let stats = MonthStats.calculate(
            days: [
                day(1, [a100, a101, a106], ticked: ["101", "106"], hours: 2),
                day(2, [a100], ticked: ["100"]),
                day(3, [a102], ticked: [], manualHours: 1),
            ],
            now: now
        )
        #expect(stats.earned == Money(minorUnits: 11200))
        #expect(stats.cleanedCount == 3)
        #expect(stats.workingDays == 2)
        #expect(stats.workedDuration == .seconds(3 * 3600))
        #expect(stats.earningsPerHour == Money(minorUnits: 2800))
        #expect(stats.averagePerWorkingDay == Money(minorUnits: 5600))
    }

    @Test(arguments: [(1000, 3, 333), (1001, 2, 501)])
    func roundsPerHourHalfUp(earnedMinorUnits: Int, hours: Int, expectedMinorUnits: Int) {
        let timed = day(1, [.fixture("x", minorUnits: earnedMinorUnits)], ticked: ["x"], hours: hours)
        let stats = MonthStats.calculate(days: [timed], now: now)
        #expect(stats.earningsPerHour == Money(minorUnits: expectedMinorUnits))
    }

    @Test func ignoresADayWithZeroRecordedTime() {
        let stats = MonthStats.calculate(
            days: [day(1, [a100], ticked: ["100"], manualHours: 0)],
            now: now
        )
        #expect(stats.earningsPerHour == nil)
    }

    @Test func ranksTheMostFrequentApartments() {
        let stats = MonthStats.calculate(
            days: [
                day(1, [a100, a101, a102], ticked: ["100", "101", "102"]),
                day(2, [a100, a102, a103], ticked: ["100", "102", "103"]),
                day(3, [a100, a101], ticked: ["100", "101"]),
            ],
            now: now
        )
        #expect(stats.topApartments.map(\.name) == ["100", "101", "102"])
        #expect(stats.topApartments.map(\.count) == [3, 2, 2])
    }

    @Test func namesAnApartmentByItsLatestSnapshot() {
        var renamed = a100
        renamed.name = "100A"
        let stats = MonthStats.calculate(
            days: [
                day(5, [renamed], ticked: ["100A"]),
                day(1, [a100], ticked: ["100"]),
            ],
            now: now
        )
        #expect(stats.topApartments.map(\.name) == ["100A"])
    }
}

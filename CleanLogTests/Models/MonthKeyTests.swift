import Testing

@testable import CleanLog

struct MonthKeyTests {
    @Test func stepsAcrossYears() {
        #expect(MonthKey(year: 2026, month: 1).previous == MonthKey(year: 2025, month: 12))
        #expect(MonthKey(year: 2026, month: 12).next == MonthKey(year: 2027, month: 1))
    }

    @Test func listsItsDays() {
        let days = MonthKey(year: 2026, month: 2).days(in: .warsaw)
        #expect(days.count == 28)
        #expect(days.first == DayKey(year: 2026, month: 2, day: 1))
        #expect(days.last == DayKey(year: 2026, month: 2, day: 28))
    }

    @Test func containsOnlyItsOwnDays() {
        let february = MonthKey(year: 2026, month: 2)
        #expect(february.contains(DayKey(year: 2026, month: 2, day: 28)))
        #expect(!february.contains(DayKey(year: 2026, month: 3, day: 1)))
    }

    @Test func boundsItsStorageRange() {
        let february = MonthKey(year: 2026, month: 2)
        #expect(february.firstDayStorageValue == 20_260_201)
        #expect(february.lastDayStorageValue == 20_260_231)
    }

    @Test func ordersChronologically() {
        #expect(MonthKey(year: 2025, month: 12) < MonthKey(year: 2026, month: 1))
    }
}

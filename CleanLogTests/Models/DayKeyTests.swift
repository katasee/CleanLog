import Foundation
import Testing

@testable import CleanLog

struct DayKeyTests {
    @Test func readsTheDayOfADateInTheGivenCalendar() {
        let key = DayKey(.warsaw(2026, 11, 13, 23, 59), calendar: .warsaw)
        #expect(key == DayKey(year: 2026, month: 11, day: 13))
    }

    @Test func startDateIsMidnightInTheCalendar() {
        let key = DayKey(year: 2026, month: 11, day: 13)
        #expect(key.startDate(in: .warsaw) == .warsaw(2026, 11, 13))
    }

    @Test func addsDaysAcrossDaylightSavingTime() {
        let saturday = DayKey(year: 2026, month: 3, day: 28)
        #expect(saturday.adding(days: 1, calendar: .warsaw) == DayKey(year: 2026, month: 3, day: 29))
        #expect(saturday.adding(days: 2, calendar: .warsaw) == DayKey(year: 2026, month: 3, day: 30))
    }

    @Test func addsDaysAcrossMonthsAndYears() {
        let lastOfOctober = DayKey(year: 2026, month: 10, day: 31)
        #expect(lastOfOctober.adding(days: 1, calendar: .warsaw) == DayKey(year: 2026, month: 11, day: 1))
        let newYear = DayKey(year: 2027, month: 1, day: 1)
        #expect(newYear.adding(days: -1, calendar: .warsaw) == DayKey(year: 2026, month: 12, day: 31))
    }

    @Test func roundTripsThroughTheStorageValue() {
        let key = DayKey(year: 2026, month: 11, day: 13)
        #expect(key.storageValue == 20_261_113)
        #expect(DayKey(storageValue: 20_261_113) == key)
        #expect(DayKey(storageValue: 20_261_340) == nil)
        #expect(DayKey(storageValue: 20_261_100) == nil)
    }

    @Test func ordersChronologically() {
        let ninth = DayKey(year: 2026, month: 11, day: 9)
        let thirteenth = DayKey(year: 2026, month: 11, day: 13)
        let december = DayKey(year: 2026, month: 12, day: 1)
        #expect(ninth < thirteenth)
        #expect(thirteenth < december)
    }

    @Test func knowsItsMonth() {
        #expect(DayKey(year: 2026, month: 11, day: 13).monthKey == MonthKey(year: 2026, month: 11))
    }

    @Test(arguments: [(12, DayKind.past), (13, .today), (14, .future)])
    func knowsItsKind(day: Int, kind: DayKind) {
        let today = DayKey(year: 2026, month: 11, day: 13)
        #expect(DayKey(year: 2026, month: 11, day: day).kind(relativeTo: today) == kind)
    }
}

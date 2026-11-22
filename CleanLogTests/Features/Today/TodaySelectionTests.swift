import Foundation
import Testing

@testable import CleanLog

struct TodaySelectionTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)

    @Test func startsOnToday() {
        let selection = TodaySelection(today: today)
        #expect(selection.day == today)
        #expect(selection.isShowingToday)
    }

    @Test func stepsAcrossAMonth() {
        var selection = TodaySelection(today: DayKey(year: 2026, month: 11, day: 30))
        selection.step(by: 1, calendar: .warsaw)
        #expect(selection.day == DayKey(year: 2026, month: 12, day: 1))
        #expect(!selection.isShowingToday)
    }

    @Test func jumpsBackToToday() {
        var selection = TodaySelection(today: today)
        selection.step(by: -3, calendar: .warsaw)
        selection.showToday()
        #expect(selection.day == today)
        #expect(selection.isShowingToday)
    }

    @Test func followsMidnightOnlyFromToday() {
        let tomorrow = DayKey(year: 2026, month: 11, day: 14)
        var onToday = TodaySelection(today: today)
        onToday.advance(to: tomorrow)
        #expect(onToday.day == tomorrow)
        #expect(onToday.today == tomorrow)

        var onPastDay = TodaySelection(today: today)
        onPastDay.step(by: -3, calendar: .warsaw)
        onPastDay.advance(to: tomorrow)
        #expect(onPastDay.day == DayKey(year: 2026, month: 11, day: 10))
        #expect(onPastDay.today == tomorrow)
    }

    @Test func waitsUntilMidnight() {
        let almostMidnight = Date.warsaw(2026, 11, 13, 23, 59).addingTimeInterval(30)
        #expect(TodaySelection.timeUntilNextDay(after: almostMidnight, calendar: .warsaw) == .seconds(30))
    }

    @Test func waitsTheRealLengthOfADaylightSavingDay() {
        let startOfChange = Date.warsaw(2026, 10, 25)
        #expect(TodaySelection.timeUntilNextDay(after: startOfChange, calendar: .warsaw) == .seconds(25 * 3600))
    }
}

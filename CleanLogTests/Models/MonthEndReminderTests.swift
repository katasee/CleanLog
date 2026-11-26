import Foundation
import Testing

@testable import CleanLog

struct MonthEndReminderTests {
    private let november = MonthKey(year: 2026, month: 11)
    private let on = MonthEndReminderSettings(isOn: true, time: ReminderTime(hour: 18, minute: 0))

    private func next(
        settings: MonthEndReminderSettings? = nil,
        month: MonthKey? = nil,
        hasCleanedApartment: Bool = true,
        now: Date = .warsaw(2026, 11, 26, 9)
    ) -> MonthEndReminder? {
        MonthEndReminder.next(
            settings: settings ?? on,
            month: month ?? november,
            hasCleanedApartment: hasCleanedApartment,
            now: now,
            calendar: .warsaw
        )
    }

    @Test func initialIsOffAtSix() {
        let expected = MonthEndReminderSettings(isOn: false, time: ReminderTime(hour: 18, minute: 0))
        #expect(MonthEndReminderSettings.initial == expected)
    }

    private func reminder(_ year: Int, _ month: Int, _ day: Int) -> MonthEndReminder {
        MonthEndReminder(
            month: MonthKey(year: year, month: month),
            day: DayKey(year: year, month: month, day: day),
            time: on.time
        )
    }

    @Test func firesOnTheLastDayOfTheMonth() {
        let december = MonthKey(year: 2026, month: 12)
        let february = MonthKey(year: 2028, month: 2)

        #expect(next() == reminder(2026, 11, 30))
        #expect(next(month: december, now: .warsaw(2026, 12, 1, 9)) == reminder(2026, 12, 31))
        #expect(next(month: february, now: .warsaw(2028, 2, 3, 9)) == reminder(2028, 2, 29))
    }

    @Test func noReminderWhenOff() {
        #expect(next(settings: .initial) == nil)
    }

    @Test func noReminderForAMonthWithNothingCleaned() {
        #expect(next(hasCleanedApartment: false) == nil)
    }

    @Test func noReminderOnceTheMomentHasPassed() {
        #expect(next(now: .warsaw(2026, 11, 30, 18)) == nil)
        #expect(next(now: .warsaw(2026, 11, 30, 17, 59)) != nil)
    }
}

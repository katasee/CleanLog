import Foundation
import Testing

@testable import CleanLog

struct ReminderTimeTests {
    @Test func readsTheHourAndMinute() {
        let time = ReminderTime(.warsaw(2026, 11, 26, 7, 45), calendar: .warsaw)
        #expect(time == ReminderTime(hour: 7, minute: 45))
    }

    @Test func placesTheTimeOnADay() {
        let day = DayKey(year: 2026, month: 11, day: 30)
        let date = ReminderTime(hour: 18, minute: 0).date(on: day, calendar: .warsaw)
        #expect(date == .warsaw(2026, 11, 30, 18))
    }
}

import Foundation
import Testing

@testable import CleanLog

struct DayFormatTests {
    private let uk = Locale(identifier: "uk_UA")
    private let en = Locale(identifier: "en_US")
    private let nov12 = DayKey(year: 2026, month: 11, day: 12)
    private let nov13 = DayKey(year: 2026, month: 11, day: 13)

    @Test func formatsTheWeekdayAndDate() {
        #expect(DayFormat.weekdayAndDate(nov13, calendar: .warsaw, locale: uk) == "Пʼятниця, 13 листопада")
        #expect(DayFormat.weekdayAndDate(nov13, calendar: .warsaw, locale: en) == "Friday, November 13")
    }

    @Test func formatsTheDayAndMonth() {
        #expect(DayFormat.dayAndMonth(nov12, calendar: .warsaw, locale: uk) == "12 листопада")
        #expect(DayFormat.dayAndMonth(nov12, calendar: .warsaw, locale: en) == "November 12")
    }

    @Test func formatsTheWeekday() {
        #expect(DayFormat.weekday(nov12, calendar: .warsaw, locale: uk) == "Четвер")
        #expect(DayFormat.weekday(nov12, calendar: .warsaw, locale: en) == "Thursday")
    }

    @Test func formatsTheStandaloneMonth() {
        let november = MonthKey(year: 2026, month: 11)
        #expect(DayFormat.month(november, calendar: .warsaw, locale: uk) == "Листопад")
        #expect(DayFormat.month(november, calendar: .warsaw, locale: en) == "November")
    }

    @Test func formatsTheTimeInTheCalendarsZone() {
        #expect(DayFormat.time(.warsaw(2026, 11, 13, 7, 40), calendar: .warsaw, locale: uk) == "07:40")
        #expect(DayFormat.time(.warsaw(2026, 11, 13, 7, 40), calendar: .warsaw, locale: en) == "7:40\u{202F}AM")
    }
}

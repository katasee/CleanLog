import Foundation
import Testing

@testable import CleanLog

struct ReminderRequestTests {
    private let november = MonthKey(year: 2026, month: 11)

    private func request(locale: Locale = Locale(identifier: "uk_UA")) -> ReminderRequest {
        let reminder = MonthEndReminder(
            month: november,
            day: DayKey(year: 2026, month: 11, day: 30),
            time: ReminderTime(hour: 18, minute: 0)
        )
        return ReminderRequest(reminder, calendar: .warsaw, locale: locale)
    }

    @Test func buildsTheTitleAndBody() {
        #expect(request().title == "Час надіслати звіт")
        #expect(request().body == "Звіт за листопад готовий — надішли його у WhatsApp.")
    }

    @Test func buildsTheBodyInEnglish() {
        #expect(request(locale: Locale(identifier: "en_US")).body == "Your November report is ready to send.")
    }

    @Test func fireDateHasNoTimeZone() {
        let fireDate = request().fireDate
        let lastDayAtSix = DateComponents(
            year: 2026,
            month: 11,
            day: 30,
            hour: 18,
            minute: 0
        )
        #expect(fireDate == lastDayAtSix)
        #expect(fireDate.timeZone == nil)
        #expect(fireDate.calendar == nil)
    }

    @Test func carriesTheMonth() {
        #expect(request().month == november)
        #expect(ReminderRequest.month(from: request().userInfo) == november)
    }

    @Test func ignoresAForeignPayload() {
        #expect(ReminderRequest.month(from: [:]) == nil)
        #expect(ReminderRequest.month(from: ["year": 2026, "month": 13]) == nil)
    }
}

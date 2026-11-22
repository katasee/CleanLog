import Foundation
import Testing

@testable import CleanLog

struct DurationFormatTests {
    @Test func formatsAClock() {
        #expect(DurationFormat.clock(.seconds(4 * 3600 + 12 * 60 + 35)) == "4:12:35")
        #expect(DurationFormat.clock(.zero) == "0:00:00")
        #expect(DurationFormat.clock(.seconds(-5)) == "0:00:00")
    }

    @Test func formatsHoursAndMinutes() {
        #expect(DurationFormat.short(.seconds(5 * 3600 + 10 * 60)) == "5:10")
        #expect(DurationFormat.short(.seconds(59)) == "0:00")
        #expect(DurationFormat.short(.seconds(62 * 3600)) == "62:00")
    }

    @Test func dropsFractionsOfASecond() {
        #expect(DurationFormat.clock(.milliseconds(61_999)) == "0:01:01")
    }

    @Test func formatsAPause() {
        #expect(DurationFormat.pause(.seconds(25 * 60), locale: Locale(identifier: "uk_UA")) == "25 хв")
        #expect(DurationFormat.pause(.seconds(85 * 60), locale: Locale(identifier: "en_US")) == "1 hr, 25 min")
    }
}

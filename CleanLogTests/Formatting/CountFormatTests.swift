import Foundation
import Testing

@testable import CleanLog

struct CountFormatTests {
    @Test func groupsThousandsByLocale() {
        #expect(CountFormat.string(63, locale: Locale(identifier: "uk_UA")) == "63")
        #expect(CountFormat.string(1_200, locale: Locale(identifier: "uk_UA")) == "1\u{00A0}200")
        #expect(CountFormat.string(1_200, locale: Locale(identifier: "en_US")) == "1,200")
    }
}

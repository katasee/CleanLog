import Foundation
import Testing

@testable import CleanLog

struct MoneyFormatTests {
    private let ukrainian = Locale(identifier: "uk_UA")
    private let english = Locale(identifier: "en_US")
    private let polish = Locale(identifier: "pl_PL")

    @Test func formatsInUkrainian() {
        #expect(MoneyFormat.string(Money(minorUnits: 201_600), locale: ukrainian) == "2\u{00A0}016\u{00A0}zł")
        #expect(MoneyFormat.string(Money(minorUnits: 2850), locale: ukrainian) == "28,50\u{00A0}zł")
        #expect(MoneyFormat.string(Money(minorUnits: 2800), locale: ukrainian) == "28\u{00A0}zł")
        #expect(MoneyFormat.string(.zero, locale: ukrainian) == "0\u{00A0}zł")
    }

    @Test func formatsInEnglish() {
        #expect(MoneyFormat.string(Money(minorUnits: 201_600), locale: english) == "2,016\u{00A0}zł")
        #expect(MoneyFormat.string(Money(minorUnits: 2850), locale: english) == "28.50\u{00A0}zł")
    }

    @Test func formatsInPolish() {
        #expect(MoneyFormat.string(Money(minorUnits: 201_600), locale: polish) == "2016\u{00A0}zł")
        #expect(MoneyFormat.string(Money(minorUnits: 1_234_500), locale: polish) == "12\u{00A0}345\u{00A0}zł")
    }

    @Test func formatsAnAmountWithoutTheCurrency() {
        #expect(MoneyFormat.amount(Money(minorUnits: 22_400), locale: ukrainian) == "224")
        #expect(MoneyFormat.amount(Money(minorUnits: 2850), locale: ukrainian) == "28,50")
        #expect(MoneyFormat.amount(Money(minorUnits: 201_600), locale: ukrainian) == "2\u{00A0}016")
    }

    @Test func neverBreaksALine() {
        let text = MoneyFormat.string(Money(minorUnits: 123_456_700), locale: ukrainian)
        #expect(!text.contains(" "))
    }
}

import Foundation
import Testing

@testable import CleanLog

struct MoneyInputTests {
    private let ukrainian = Locale(identifier: "uk_UA")
    private let english = Locale(identifier: "en_US")
    private let polish = Locale(identifier: "pl_PL")

    @Test(arguments: [
        ("28", 2800), ("28,50", 2850), ("28.5", 2850), (" 28 ", 2800), ("028", 2800), ("0", 0),
    ])
    func parsesAPrice(text: String, minorUnits: Int) {
        #expect(MoneyInput.parse(text) == Money(minorUnits: minorUnits))
    }

    @Test(arguments: ["", " ", "28,505", "-5", "2 016", "28,", ",5", "abc", "1e3", "99999999999999999999", "٢٨"])
    func rejectsWhatIsNotAPrice(text: String) {
        #expect(MoneyInput.parse(text) == nil)
    }

    @Test func rejectsAPriceThatOverflows() {
        #expect(MoneyInput.parse(String(Int.max / 10)) == nil)
    }

    @Test func writesAPriceForEditing() {
        #expect(MoneyInput.string(Money(minorUnits: 2800), locale: ukrainian) == "28")
        #expect(MoneyInput.string(Money(minorUnits: 2850), locale: ukrainian) == "28,50")
        #expect(MoneyInput.string(Money(minorUnits: 2805), locale: ukrainian) == "28,05")
        #expect(MoneyInput.string(Money(minorUnits: 2850), locale: english) == "28.50")
        #expect(MoneyInput.string(Money(minorUnits: 201_600), locale: english) == "2016")
    }

    @Test func readsBackWhatItWrites() {
        let price = Money(minorUnits: 3550)
        #expect(MoneyInput.parse(MoneyInput.string(price, locale: polish)) == price)
    }
}

import Testing

@testable import CleanLog

struct ApartmentNameOrderTests {
    private func sorted(_ names: [String]) -> [String] {
        names.sorted(by: ApartmentNameOrder.areInIncreasingOrder)
    }

    @Test func putsDigitNamesFirstInNumericOrder() {
        #expect(sorted(["6piw", "100", "54", "133kol", "96"]) == ["54", "96", "100", "6piw", "133kol"])
    }

    @Test func comparesDigitNamesAsNumbers() {
        #expect(sorted(["100", "99", "1000"]) == ["99", "100", "1000"])
    }

    @Test func comparesOtherNamesNumericallyAndCaseInsensitively() {
        #expect(sorted(["10a", "9b", "Bravo", "alpha"]) == ["9b", "10a", "alpha", "Bravo"])
    }

    @Test func breaksTiesByPlainOrder() {
        #expect(sorted(["54", "054"]) == ["054", "54"])
        #expect(sorted(["6piw", "6PIW"]) == ["6PIW", "6piw"])
    }
}

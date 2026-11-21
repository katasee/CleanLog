import Testing

@testable import CleanLog

struct MoneyTests {
    @Test func multipliesAndAdds() {
        #expect(Money(minorUnits: 2800) * 6 + Money(minorUnits: 5600) == Money(minorUnits: 22400))
    }

    @Test func subtractsAndAccumulates() {
        var total = Money(minorUnits: 1000)
        total += Money(minorUnits: 500)
        #expect(total - Money(minorUnits: 200) == Money(minorUnits: 1300))
    }

    @Test func sumsASequence() {
        #expect([Money(minorUnits: 2800), Money(minorUnits: 5600)].sum() == Money(minorUnits: 8400))
        #expect([Money]().sum() == .zero)
    }

    @Test func compares() {
        #expect(Money(minorUnits: 100) < Money(minorUnits: 200))
    }
}

import Testing

@testable import CleanLog

struct MoneyTests {
    @Test func multipliesAndAdds() {
        #expect(Money(grosze: 2800) * 6 + Money(grosze: 5600) == Money(grosze: 22400))
    }

    @Test func subtractsAndAccumulates() {
        var total = Money(grosze: 1000)
        total += Money(grosze: 500)
        #expect(total - Money(grosze: 200) == Money(grosze: 1300))
    }

    @Test func sumsASequence() {
        #expect([Money(grosze: 2800), Money(grosze: 5600)].sum() == Money(grosze: 8400))
        #expect([Money]().sum() == .zero)
    }

    @Test func compares() {
        #expect(Money(grosze: 100) < Money(grosze: 200))
    }
}

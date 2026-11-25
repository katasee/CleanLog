import Testing

@testable import CleanLog

struct EarningsChangeTests {
    private func change(_ current: Int, vs previous: Int) -> EarningsChange? {
        EarningsChange.between(
            current: Money(minorUnits: current),
            previous: Money(minorUnits: previous)
        )
    }

    @Test func risesByARoundedPercent() {
        #expect(change(201_600, vs: 185_000) == EarningsChange(direction: .up, percent: 9))
    }

    @Test func fallsByARoundedPercent() {
        #expect(change(150_000, vs: 170_000) == EarningsChange(direction: .down, percent: 12))
    }

    @Test func roundsHalfUp() {
        #expect(change(100_500, vs: 100_000) == EarningsChange(direction: .up, percent: 1))
    }

    @Test func equalIsTheSame() {
        #expect(change(100_000, vs: 100_000) == EarningsChange(direction: .same, percent: 0))
    }

    @Test func aChangeThatRoundsToZeroIsTheSame() {
        #expect(change(100_001, vs: 100_000) == EarningsChange(direction: .same, percent: 0))
    }

    @Test func isNilWhenThePreviousMonthEarnedNothing() {
        #expect(change(100_000, vs: 0) == nil)
    }

    @Test func isNilWhenThisMonthEarnedNothing() {
        #expect(change(0, vs: 100_000) == nil)
    }
}

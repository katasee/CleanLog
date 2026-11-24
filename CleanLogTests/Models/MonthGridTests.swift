import Testing

@testable import CleanLog

struct MonthGridTests {
    @Test func novemberStartsOnSundayInAMondayFirstWeek() {
        let weeks = MonthGrid.weeks(of: MonthKey(year: 2026, month: 11), calendar: .mondayFirst)
        #expect(weeks.count == 6)
        #expect(weeks[0] == [nil, nil, nil, nil, nil, nil, DayKey(year: 2026, month: 11, day: 1)])
        #expect(weeks[5][0] == DayKey(year: 2026, month: 11, day: 30))
        #expect(weeks[5][1...].allSatisfy { $0 == nil })
    }

    @Test func juneStartsOnTheFirstColumn() {
        let weeks = MonthGrid.weeks(of: MonthKey(year: 2026, month: 6), calendar: .mondayFirst)
        #expect(weeks[0][0] == DayKey(year: 2026, month: 6, day: 1))
        #expect(weeks.count == 5)
    }

    @Test func sundayFirstShiftsTheBlanks() {
        let weeks = MonthGrid.weeks(of: MonthKey(year: 2026, month: 11), calendar: .sundayFirst)
        #expect(weeks[0][0] == DayKey(year: 2026, month: 11, day: 1))
        #expect(weeks.count == 5)
    }

    @Test(arguments: 1...12)
    func everyWeekHasSevenColumns(month: Int) {
        let key = MonthKey(year: 2027, month: month)
        let weeks = MonthGrid.weeks(of: key, calendar: .mondayFirst)
        #expect(weeks.allSatisfy { $0.count == 7 })
        #expect(weeks.flatMap { $0 }.compactMap { $0 } == key.days(in: .mondayFirst))
    }
}

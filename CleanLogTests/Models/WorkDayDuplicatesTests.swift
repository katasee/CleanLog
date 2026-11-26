import Foundation
import Testing

@testable import CleanLog

struct WorkDayDuplicatesTests {
    private let day = DayKey(year: 2026, month: 11, day: 13)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")

    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        .warsaw(2026, 11, 13, hour, minute)
    }

    private func copy(
        id: Int,
        changedAt hour: Int,
        _ change: (inout WorkDay) -> Void = { _ in }
    ) -> Revision<WorkDay> {
        var workDay = WorkDay(
            id: .fixture(id),
            day: day,
            entries: [],
            sessions: [],
            manualDuration: nil,
            isTimerFinished: false,
            isTimeDropped: false
        )
        change(&workDay)
        return Revision(value: workDay, changedAt: at(hour))
    }

    private func session(_ id: Int, from start: Date, to end: Date?) -> WorkSession {
        WorkSession(
            id: .fixture(id),
            start: start,
            end: end
        )
    }

    private func entry(for apartment: Apartment, cleanedAt: Date? = nil) -> DayEntry {
        var entry = DayEntry(planning: apartment)
        entry.isCleaned = cleanedAt != nil
        entry.cleanedAt = cleanedAt
        return entry
    }

    @Test func oneCopyIsItself() {
        let only = copy(id: 1, changedAt: 9) { day in
            day.entries = [entry(for: a100, cleanedAt: at(8))]
            day.sessions = [session(1, from: at(7), to: at(8))]
            day.isTimerFinished = true
        }

        #expect(WorkDayDuplicates.merged([only]) == only)
    }

    @Test func unitesEntriesOfDifferentApartments() {
        let newer = copy(id: 1, changedAt: 12) { $0.entries = [entry(for: a100)] }
        let older = copy(id: 2, changedAt: 9) { $0.entries = [entry(for: a101)] }

        let merged = WorkDayDuplicates.merged([older, newer])

        #expect(merged.value.entries.map(\.apartmentID) == [a100.id, a101.id])
    }

    @Test func aTickInEitherCopyIsKept() throws {
        let newer = copy(id: 1, changedAt: 12) { $0.entries = [entry(for: a100)] }
        let older = copy(id: 2, changedAt: 9) { $0.entries = [entry(for: a100, cleanedAt: at(10))] }

        let merged = WorkDayDuplicates.merged([newer, older])

        let only = try #require(merged.value.entries.first)
        #expect(merged.value.entries.count == 1)
        #expect(only.isCleaned)
        #expect(only.cleanedAt == at(10))
    }

    @Test func theEarlierTickTimeIsKept() throws {
        let newer = copy(id: 1, changedAt: 12) { $0.entries = [entry(for: a100, cleanedAt: at(10))] }
        let older = copy(id: 2, changedAt: 9) { $0.entries = [entry(for: a100, cleanedAt: at(8))] }

        let merged = WorkDayDuplicates.merged([newer, older])

        #expect(try #require(merged.value.entries.first).cleanedAt == at(8))
    }

    @Test func theNewerSnapshotWins() throws {
        let raised = Apartment(
            id: a100.id,
            name: a100.name,
            price: Money(minorUnits: 3000),
            accessCode: nil,
            isReportedSeparately: false,
            createdAt: a100.createdAt
        )
        let older = copy(id: 1, changedAt: 9) { $0.entries = [entry(for: a100)] }
        let newer = copy(id: 2, changedAt: 12) { $0.entries = [entry(for: raised)] }

        let merged = WorkDayDuplicates.merged([older, newer])

        #expect(try #require(merged.value.entries.first).price == Money(minorUnits: 3000))
    }

    @Test func unitesTwoEntriesOfOneApartmentInOneCopy() {
        let only = copy(id: 1, changedAt: 9) { day in
            day.entries = [entry(for: a100), entry(for: a100, cleanedAt: at(8))]
        }

        let merged = WorkDayDuplicates.merged([only])

        #expect(merged.value.entries.count == 1)
        #expect(merged.value.entries.first?.isCleaned == true)
    }

    @Test func overlappingSessionsFold() {
        let first = copy(id: 1, changedAt: 12) { $0.sessions = [session(1, from: at(9), to: at(11))] }
        let second = copy(id: 2, changedAt: 13) { $0.sessions = [session(2, from: at(10), to: at(12))] }

        let merged = WorkDayDuplicates.merged([first, second])

        #expect(merged.value.sessions == [session(1, from: at(9), to: at(12))])
        #expect(merged.value.workedDuration(now: at(14)) == .seconds(3 * 3600))
    }

    @Test func touchingSessionsFold() {
        let first = copy(id: 1, changedAt: 12) { $0.sessions = [session(1, from: at(9), to: at(10))] }
        let second = copy(id: 2, changedAt: 13) { $0.sessions = [session(2, from: at(10), to: at(11))] }

        let merged = WorkDayDuplicates.merged([first, second])

        #expect(merged.value.sessions == [session(1, from: at(9), to: at(11))])
    }

    @Test func aContainedSessionDisappears() {
        let first = copy(id: 1, changedAt: 12) { $0.sessions = [session(1, from: at(9), to: at(12))] }
        let second = copy(id: 2, changedAt: 13) { $0.sessions = [session(2, from: at(10), to: at(11))] }

        let merged = WorkDayDuplicates.merged([first, second])

        #expect(merged.value.sessions == [session(1, from: at(9), to: at(12))])
    }

    @Test func separateSessionsStay() {
        let first = copy(id: 1, changedAt: 12) { $0.sessions = [session(1, from: at(11), to: at(12))] }
        let second = copy(id: 2, changedAt: 13) { $0.sessions = [session(2, from: at(9), to: at(10))] }

        let merged = WorkDayDuplicates.merged([first, second])

        #expect(merged.value.sessions == [session(2, from: at(9), to: at(10)), session(1, from: at(11), to: at(12))])
    }

    @Test func anOpenSessionSwallowsLaterOnes() {
        let first = copy(id: 1, changedAt: 12) { $0.sessions = [session(1, from: at(9), to: nil)] }
        let second = copy(id: 2, changedAt: 13) { $0.sessions = [session(2, from: at(10), to: at(11))] }

        let merged = WorkDayDuplicates.merged([first, second])

        #expect(merged.value.sessions == [session(1, from: at(9), to: nil)])
        #expect(merged.value.timerState == .running(since: at(9)))
    }

    @Test func aLaterOpenSessionOpensTheFold() {
        let first = copy(id: 1, changedAt: 12) { $0.sessions = [session(1, from: at(9), to: at(11))] }
        let second = copy(id: 2, changedAt: 13) { $0.sessions = [session(2, from: at(10), to: nil)] }

        let merged = WorkDayDuplicates.merged([first, second])

        #expect(merged.value.sessions == [session(1, from: at(9), to: nil)])
    }

    @Test func theNewerManualDurationWins() {
        let older = copy(id: 1, changedAt: 9) { $0.manualDuration = .seconds(2 * 3600) }
        let newer = copy(id: 2, changedAt: 12) { $0.manualDuration = .seconds(3 * 3600) }

        #expect(WorkDayDuplicates.merged([older, newer]).value.manualDuration == .seconds(3 * 3600))
    }

    @Test func aSingleManualDurationIsKept() {
        let older = copy(id: 1, changedAt: 9) { $0.manualDuration = .seconds(2 * 3600) }
        let newer = copy(id: 2, changedAt: 12)

        #expect(WorkDayDuplicates.merged([newer, older]).value.manualDuration == .seconds(2 * 3600))
    }

    @Test func theNewerTimerFlagsWin() {
        let older = copy(id: 1, changedAt: 9) { day in
            day.sessions = [session(1, from: at(7), to: at(8))]
            day.isTimeDropped = true
        }
        let newer = copy(id: 2, changedAt: 12) { day in
            day.sessions = [session(2, from: at(9), to: at(10))]
            day.isTimerFinished = true
        }

        let merged = WorkDayDuplicates.merged([older, newer]).value

        #expect(merged.isTimerFinished)
        #expect(!merged.isTimeDropped)
    }

    @Test(arguments: [9, 14])
    func keepsTheSmallestIDAndTheLatestChange(largeChangedAt hour: Int) {
        let large = copy(id: 3, changedAt: hour)
        let small = copy(id: 1, changedAt: 12)

        let merged = WorkDayDuplicates.merged([large, small])

        #expect(merged.value.id == .fixture(1))
        #expect(merged.changedAt == at(max(hour, 12)))
    }

    @Test func pointingKeepsTheSnapshot() {
        let original = entry(for: a100, cleanedAt: at(8))

        let repointed = original.pointing(to: a101.id)

        #expect(repointed.apartmentID == a101.id)
        #expect(repointed.id == original.id)
        #expect(repointed.name == "100")
        #expect(repointed.cleanedAt == at(8))
    }
}

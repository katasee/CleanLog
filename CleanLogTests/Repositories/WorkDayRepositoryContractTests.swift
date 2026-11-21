import Foundation
import Testing

@testable import CleanLog

struct WorkDayRepositoryContractTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101", sortOrder: 1)

    private func key(_ day: Int, month: Int = 11) -> DayKey {
        DayKey(year: 2026, month: month, day: day)
    }

    @Test(arguments: RepositoryKind.allCases)
    func anUnwrittenDayIsEmpty(kind: RepositoryKind) async {
        var stream = kind.makeStore().workDays.day(today).makeAsyncIterator()
        let day = await stream.next()
        #expect(day?.day == today)
        #expect(day?.entries.isEmpty == true)
    }

    @Test(arguments: RepositoryKind.allCases)
    func publishesAnUpdate(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        var stream = repository.day(today).makeAsyncIterator()
        _ = await stream.next()

        try await repository.update(today) { $0.planning([a100, a101]) }

        #expect(await stream.next()?.entries.map(\.name) == ["100", "101"])
    }

    @Test(arguments: RepositoryKind.allCases)
    func keepsTheDayWhenARuleRefuses(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        try await repository.update(key(14)) { $0.planning([a100]) }

        await #expect(throws: WorkDayError.futureDay) {
            try await repository.update(key(14)) { day in
                try day.settingCleaned(
                    day.entries[0].id,
                    to: true,
                    now: .warsaw(2026, 11, 13, 9),
                    today: today
                )
            }
        }

        var stream = repository.day(key(14)).makeAsyncIterator()
        #expect(await stream.next()?.hasCleanedEntries == false)
    }

    @Test(arguments: RepositoryKind.allCases)
    func appliesSuccessiveChangesToTheStoredDay(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        try await repository.update(today) { $0.planning([a100]) }
        try await repository.update(today) { $0.planning([a101]) }
        try await repository.update(today) { day in
            try day.settingCleaned(
                day.entries[0].id,
                to: true,
                now: .warsaw(2026, 11, 13, 9),
                today: today
            )
        }

        var stream = repository.day(today).makeAsyncIterator()
        let day = try #require(await stream.next())
        #expect(day.entries.map(\.name) == ["100", "101"])
        #expect(day.cleanedCount == 1)
    }

    @Test(arguments: RepositoryKind.allCases)
    func listsOnlyTheMonthsDaysInOrder(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        for day in [key(20), key(3), key(31, month: 10), key(1, month: 12)] {
            try await repository.update(day) { $0.planning([a100]) }
        }

        var stream = repository.days(in: MonthKey(year: 2026, month: 11)).makeAsyncIterator()
        #expect(await stream.next()?.map(\.day) == [key(3), key(20)])
    }

    @Test(arguments: RepositoryKind.allCases)
    func findsTheLatestEarlierDayWithEntries(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        #expect(try await repository.latestDayWithEntries(before: today) == nil)

        try await repository.update(key(10)) { $0.planning([a100]) }
        try await repository.update(key(11)) { $0.planning([a101]) }
        try await repository.update(key(12)) { $0.planning([a100]) }
        try await repository.update(key(12)) { $0.removingEntry($0.entries[0].id) }
        try await repository.update(today) { $0.planning([a100]) }

        let latest = try await repository.latestDayWithEntries(before: today)
        #expect(latest?.day == key(11))
    }

    @Test(arguments: RepositoryKind.allCases)
    func doesNotStoreABlankDay(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        try await repository.update(today) { $0 }

        var stream = repository.days(in: MonthKey(year: 2026, month: 11)).makeAsyncIterator()
        #expect(await stream.next() == [])
    }

    @Test(arguments: RepositoryKind.allCases)
    func notifiesEveryObserverOfTheDay(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        var first = repository.day(today).makeAsyncIterator()
        var month = repository.days(in: today.monthKey).makeAsyncIterator()
        _ = await first.next()
        _ = await month.next()

        try await repository.update(today) { $0.planning([a100]) }

        #expect(await first.next()?.entries.count == 1)
        #expect(await month.next()?.count == 1)
    }

    @Test(arguments: RepositoryKind.allCases)
    func survivesACancelledObserver(kind: RepositoryKind) async throws {
        let repository = kind.makeStore().workDays
        let observer = Task {
            for await _ in repository.day(today) {}
        }
        await Task.yield()
        observer.cancel()
        await observer.value

        try await repository.update(today) { $0.planning([a100]) }
        var stream = repository.day(today).makeAsyncIterator()
        #expect(await stream.next()?.entries.count == 1)
    }
}

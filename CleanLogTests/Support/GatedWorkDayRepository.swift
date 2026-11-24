import Foundation

@testable import CleanLog

final class GatedWorkDayRepository: WorkDayRepository {
    private let wrapped: FakeWorkDayRepository
    private let gate = AsyncStream<Void>.makeStream()
    private(set) var updateCount = 0

    init(_ days: [WorkDay]) {
        wrapped = FakeWorkDayRepository(days)
    }

    func release() {
        gate.continuation.finish()
    }

    func day(_ day: DayKey) -> AsyncStream<WorkDay> {
        wrapped.day(day)
    }

    func days(in month: MonthKey) -> AsyncStream<[WorkDay]> {
        wrapped.days(in: month)
    }

    func latestDayWithEntries(before day: DayKey) async throws -> WorkDay? {
        try await wrapped.latestDayWithEntries(before: day)
    }

    func daysWithOpenSession(before day: DayKey) async throws -> [WorkDay] {
        try await wrapped.daysWithOpenSession(before: day)
    }

    func update(_ day: DayKey, _ change: (WorkDay) throws -> WorkDay) async throws {
        updateCount += 1
        for await _ in gate.stream {}
        try await wrapped.update(day, change)
    }
}

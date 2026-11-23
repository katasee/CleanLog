import Foundation

@testable import CleanLog

final class FailingWorkDayRepository: WorkDayRepository {
    struct WriteRefused: Error {}

    private let wrapped: FakeWorkDayRepository

    init(_ days: [WorkDay]) {
        wrapped = FakeWorkDayRepository(days)
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
        throw WriteRefused()
    }
}

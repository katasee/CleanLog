import Foundation

protocol WorkDayRepository: AnyObject {
    func day(_ day: DayKey) -> AsyncStream<WorkDay>
    func days(in month: MonthKey) -> AsyncStream<[WorkDay]>
    func latestDayWithEntries(before day: DayKey) async throws -> WorkDay?
    func update(_ day: DayKey, _ change: (WorkDay) throws -> WorkDay) async throws
}

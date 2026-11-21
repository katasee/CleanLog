import Foundation

@testable import CleanLog

enum RepositoryKind: CaseIterable, Sendable {
    case fake

    func makeStore(now: Date = .warsaw(2026, 11, 13, 9)) -> StoreUnderTest {
        switch self {
        case .fake:
            StoreUnderTest(
                apartments: FakeApartmentRepository(now: { now }),
                workDays: FakeWorkDayRepository()
            )
        }
    }
}

struct StoreUnderTest {
    let apartments: any ApartmentRepository
    let workDays: any WorkDayRepository
    var keepAlive: Any?
}

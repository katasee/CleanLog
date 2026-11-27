import Foundation
import SwiftData

@testable import CleanLog

extension StoreUnderTest {
    static func swiftData(now: Date) -> StoreUnderTest {
        let container = ModelContainer.inMemory()
        return StoreUnderTest(
            apartments: SwiftDataApartmentRepository(container: container, now: { now }),
            workDays: SwiftDataWorkDayRepository(container: container, now: { now })
        )
    }
}

extension ModelContainer {
    static func inMemory() -> ModelContainer {
        do {
            return try ModelContainerFactory.make(inMemory: true)
        } catch {
            preconditionFailure("Could not open an in-memory store: \(error)")
        }
    }
}

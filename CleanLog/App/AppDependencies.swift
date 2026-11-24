import Observation
import SwiftData

@Observable
final class AppDependencies {
    let apartments: any ApartmentRepository
    let workDays: any WorkDayRepository

    private init(apartments: any ApartmentRepository, workDays: any WorkDayRepository) {
        self.apartments = apartments
        self.workDays = workDays
    }

    static func live() throws -> AppDependencies {
        let container = try ModelContainerFactory.make(inMemory: false)
        return AppDependencies(
            apartments: SwiftDataApartmentRepository(container: container),
            workDays: SwiftDataWorkDayRepository(container: container)
        )
    }
}

#if DEBUG
    extension AppDependencies {
        static func preview(
            apartments: any ApartmentRepository = FakeApartmentRepository(),
            workDays: any WorkDayRepository = FakeWorkDayRepository()
        ) -> AppDependencies {
            AppDependencies(apartments: apartments, workDays: workDays)
        }
    }
#endif

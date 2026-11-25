import Observation
import SwiftData

@Observable
final class AppDependencies {
    let apartments: any ApartmentRepository
    let workDays: any WorkDayRepository
    let urlAvailability: any URLAvailability
    let pasteboard: any Pasteboard

    private init(
        apartments: any ApartmentRepository,
        workDays: any WorkDayRepository,
        urlAvailability: any URLAvailability,
        pasteboard: any Pasteboard
    ) {
        self.apartments = apartments
        self.workDays = workDays
        self.urlAvailability = urlAvailability
        self.pasteboard = pasteboard
    }

    static func live() throws -> AppDependencies {
        let container = try ModelContainerFactory.make(inMemory: false)
        return AppDependencies(
            apartments: SwiftDataApartmentRepository(container: container),
            workDays: SwiftDataWorkDayRepository(container: container),
            urlAvailability: SystemURLAvailability(),
            pasteboard: SystemPasteboard()
        )
    }
}

#if DEBUG
    extension AppDependencies {
        static func preview(
            apartments: any ApartmentRepository = FakeApartmentRepository(),
            workDays: any WorkDayRepository = FakeWorkDayRepository(),
            urlAvailability: any URLAvailability = FakeURLAvailability(),
            pasteboard: any Pasteboard = FakePasteboard()
        ) -> AppDependencies {
            AppDependencies(
                apartments: apartments,
                workDays: workDays,
                urlAvailability: urlAvailability,
                pasteboard: pasteboard
            )
        }
    }
#endif

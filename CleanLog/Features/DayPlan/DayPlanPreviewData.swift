#if DEBUG
    import Foundation

    enum DayPlanPreviewData {
        static let today = DayKey(.now, calendar: .current)

        private static let regularNames = ["54", "64", "96", "100", "101", "102", "105", "115", "116", "138", "6piw"]

        static let template: [Apartment] =
            regularNames.map { apartment($0, price: 2800) } + [apartment("155", price: 5600)]

        static func dependencies(plannedCount: Int) -> AppDependencies {
            AppDependencies.preview(
                apartments: FakeApartmentRepository(template),
                workDays: FakeWorkDayRepository([WorkDay.empty(today).planning(Array(template.prefix(plannedCount)))])
            )
        }

        static func viewModel(searchText: String) -> DayPlanViewModel {
            let viewModel = DayPlanViewModel(
                day: today,
                today: today,
                apartments: FakeApartmentRepository(template),
                workDays: FakeWorkDayRepository()
            )
            viewModel.searchText = searchText
            return viewModel
        }

        private static func apartment(_ name: String, price minorUnits: Int) -> Apartment {
            Apartment(
                id: UUID(),
                name: name,
                price: Money(minorUnits: minorUnits),
                accessCode: nil,
                isReportedSeparately: minorUnits > 2800,
                createdAt: .now
            )
        }
    }
#endif

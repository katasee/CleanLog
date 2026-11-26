#if DEBUG
    import Foundation

    enum ReportPreviewData {
        private static let today = DayKey(.now, calendar: .current)

        private static let regularNames = ["100", "101", "102", "103", "104", "105", "106"]
        private static let template: [Apartment] =
            regularNames.map { apartment($0, isReportedSeparately: false) }
            + [apartment("155", isReportedSeparately: true)]

        static func viewModel(isWhatsAppInstalled: Bool) -> ReportViewModel {
            viewModel(
                workDays: FakeWorkDayRepository(cleanedDays()),
                isWhatsAppInstalled: isWhatsAppInstalled
            )
        }

        static func emptyViewModel() -> ReportViewModel {
            viewModel(workDays: FakeWorkDayRepository(), isWhatsAppInstalled: true)
        }

        private static func viewModel(
            workDays: FakeWorkDayRepository,
            isWhatsAppInstalled: Bool
        ) -> ReportViewModel {
            ReportViewModel(
                month: today.monthKey,
                today: today,
                workDays: workDays,
                urlAvailability: FakeURLAvailability(isAvailable: isWhatsAppInstalled),
                pasteboard: FakePasteboard()
            )
        }

        private static func cleanedDays() -> [WorkDay] {
            (1...today.day)
                .filter { $0 % 7 != 0 }
                .map { cleaned(DayKey(year: today.year, month: today.month, day: $0)) }
        }

        private static func cleaned(_ day: DayKey) -> WorkDay {
            let regulars = template.filter { !$0.isReportedSeparately }.prefix(3 + day.day % 5)
            let separates = day.day % 3 == 0 ? template.filter(\.isReportedSeparately) : []
            var workDay = WorkDay.empty(day).planning(Array(regulars) + separates)
            for index in workDay.entries.indices {
                workDay.entries[index].isCleaned = true
            }
            return workDay
        }

        private static func apartment(_ name: String, isReportedSeparately: Bool) -> Apartment {
            Apartment(
                id: UUID(),
                name: name,
                price: Money(minorUnits: isReportedSeparately ? 5600 : 2800),
                accessCode: nil,
                isReportedSeparately: isReportedSeparately,
                createdAt: .now
            )
        }
    }
#endif

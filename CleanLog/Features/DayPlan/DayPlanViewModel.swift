import Foundation
import Observation

@Observable @MainActor
final class DayPlanViewModel {
    private let apartments: any ApartmentRepository
    private let workDays: any WorkDayRepository
    private let day: DayKey
    private let locale: Locale
    private var template: [Apartment]?
    private var plannedIDs: Set<UUID>?
    private var selectedIDs: Set<UUID> = []

    let title: String
    var searchText = ""
    var newApartmentForm: ApartmentFormViewModel?

    init(
        day: DayKey,
        today: DayKey,
        apartments: any ApartmentRepository,
        workDays: any WorkDayRepository,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.day = day
        self.apartments = apartments
        self.workDays = workDays
        self.locale = locale
        title =
            day == today
            ? String(localized: .dayPlanTitleToday, locale: locale)
            : String(
                localized: .dayPlanTitleOther(DayFormat.dayAndMonth(day, calendar: calendar, locale: locale)),
                locale: locale
            )
    }

    var tiles: [DayPlanTile] {
        unplanned.filter(matchesSearch).map { apartment in
            DayPlanTile(
                id: apartment.id,
                name: apartment.name,
                priceText: MoneyFormat.string(apartment.price, locale: locale),
                isSelected: selectedIDs.contains(apartment.id)
            )
        }
    }

    var selectedCountText: String? {
        chosen.isEmpty ? nil : String(localized: .dayPlanSelected(chosen.count), locale: locale)
    }

    var confirmTitle: String {
        guard !chosen.isEmpty else { return String(localized: .dayPlanActionNone, locale: locale) }
        let sum = MoneyFormat.string(chosen.map(\.price).sum(), locale: locale)
        return String(localized: .dayPlanActionAdd(apartments: chosen.count, sum), locale: locale)
    }

    var emptyMessage: String? {
        guard let template, plannedIDs != nil else { return nil }
        if template.isEmpty {
            return String(localized: .dayPlanEmptyTemplate, locale: locale)
        }
        if unplanned.isEmpty {
            return String(localized: .dayPlanEmptyAllPlanned, locale: locale)
        }
        if tiles.isEmpty {
            return String(localized: .dayPlanEmptyNoMatch, locale: locale)
        }
        return nil
    }

    var canConfirm: Bool {
        !chosen.isEmpty
    }

    func toggle(_ id: Apartment.ID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func startNewApartment() {
        newApartmentForm = ApartmentFormViewModel(
            repository: apartments,
            editing: nil,
            suggestedName: tiles.isEmpty ? trimmedSearch : "",
            locale: locale,
            onAdd: { [weak self] apartment in self?.toggle(apartment.id) }
        )
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask { await self.observeTemplate() }
            group.addTask { await self.observeDay() }
        }
    }

    private var unplanned: [Apartment] {
        guard let template, let plannedIDs else { return [] }
        return template.filter { !plannedIDs.contains($0.id) }
    }

    private var chosen: [Apartment] {
        unplanned.filter { selectedIDs.contains($0.id) }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matchesSearch(_ apartment: Apartment) -> Bool {
        trimmedSearch.isEmpty || apartment.name.range(of: trimmedSearch, options: .caseInsensitive) != nil
    }

    private func observeTemplate() async {
        for await template in apartments.apartments() {
            self.template = template
        }
    }

    private func observeDay() async {
        for await workDay in workDays.day(day) {
            plannedIDs = Set(workDay.entries.map(\.apartmentID))
        }
    }
}

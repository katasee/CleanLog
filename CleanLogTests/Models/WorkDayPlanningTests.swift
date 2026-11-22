import Foundation
import Testing

@testable import CleanLog

struct WorkDayPlanningTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let yesterday = DayKey(year: 2026, month: 11, day: 12)
    private let a100 = Apartment.fixture("100")
    private let a101 = Apartment.fixture("101")
    private let a102 = Apartment.fixture("102")
    private let a106 = Apartment.fixture("106", minorUnits: 5600, separate: true)

    @Test func plansEachApartmentOnce() {
        let day = WorkDay.empty(today).planning([a100, a101]).planning([a101, a102])
        #expect(day.entries.map(\.name) == ["100", "101", "102"])
        #expect(day.entries.allSatisfy { !$0.isCleaned && $0.cleanedAt == nil })
    }

    @Test func entriesSnapshotTheApartment() throws {
        let entry = try #require(WorkDay.empty(today).planning([a106]).entries.first)
        #expect(entry.apartmentID == a106.id)
        #expect(entry.name == "106")
        #expect(entry.price == Money(minorUnits: 5600))
        #expect(entry.isReportedSeparately)
    }

    @Test func aLaterPriceChangeDoesNotTouchAPlannedEntry() throws {
        var repriced = a100
        repriced.price = Money(minorUnits: 3000)
        let day = WorkDay.empty(today).planning([a100]).planning([repriced])
        let entry = try #require(day.entries.first)
        #expect(day.entries.count == 1)
        #expect(entry.price == Money(minorUnits: 2800))
    }

    @Test func copiesAPlanUntickedWithFreshEntries() throws {
        let a205 = Apartment.fixture("205")
        let planned = WorkDay.empty(yesterday).planning([a100, a205])
        let source = try planned.settingCleaned(
            planned.entries[0].id,
            to: true,
            now: .warsaw(2026, 11, 12, 10),
            today: today
        )
        let copy = WorkDay.empty(today).copyingPlan(from: source, template: [a100, a205])
        #expect(copy.entries.map(\.name) == ["100", "205"])
        #expect(copy.entries.allSatisfy { !$0.isCleaned })
        #expect(Set(copy.entries.map(\.id)).isDisjoint(with: source.entries.map(\.id)))
        #expect(copy.entries.map(\.apartmentID) == source.entries.map(\.apartmentID))
    }

    @Test func copyingSkipsApartmentsAlreadyOnTheDay() {
        let a205 = Apartment.fixture("205")
        let source = WorkDay.empty(yesterday).planning([a100, a205])
        let copy = WorkDay.empty(today).planning([a100]).copyingPlan(from: source, template: [a100, a205])
        #expect(copy.entries.map(\.name) == ["100", "205"])
    }

    @Test func copiesOnlyTemplateApartmentsAtTheirCurrentPrice() throws {
        let source = WorkDay.fixture(yesterday, ticked: [a100], unticked: [a101, a102])
        let raised = Apartment(
            id: a100.id,
            name: "100",
            price: Money(minorUnits: 3000),
            accessCode: nil,
            isReportedSeparately: true,
            createdAt: a100.createdAt
        )
        let copy = WorkDay.empty(today).copyingPlan(from: source, template: [raised, a102])
        #expect(copy.entries.map(\.apartmentID) == [a100.id, a102.id])
        #expect(copy.entries[0].price == Money(minorUnits: 3000))
        #expect(copy.entries[0].isReportedSeparately)
        #expect(copy.entries.allSatisfy { !$0.isCleaned && $0.cleanedAt == nil })
    }

    @Test func removesOnlyTheGivenEntry() {
        let day = WorkDay.empty(today).planning([a100, a101])
        #expect(day.removingEntry(day.entries[0].id).entries.map(\.name) == ["101"])
        #expect(day.removingEntry(UUID()) == day)
    }

    @Test func ticksAndUnticksAnEntry() throws {
        let now = Date.warsaw(2026, 11, 13, 10)
        let planned = WorkDay.empty(today).planning([a100])
        let id = planned.entries[0].id
        let ticked = try planned.settingCleaned(
            id,
            to: true,
            now: now,
            today: today
        )
        #expect(ticked.entries[0].isCleaned)
        #expect(ticked.entries[0].cleanedAt == now)
        let unticked = try ticked.settingCleaned(
            id,
            to: false,
            now: now,
            today: today
        )
        #expect(!unticked.entries[0].isCleaned)
        #expect(unticked.entries[0].cleanedAt == nil)
    }

    @Test func refusesToTickOnAFutureDay() {
        let tomorrow = WorkDay.empty(DayKey(year: 2026, month: 11, day: 14)).planning([a100])
        #expect(throws: WorkDayError.futureDay) {
            try tomorrow.settingCleaned(
                tomorrow.entries[0].id,
                to: true,
                now: .warsaw(2026, 11, 13, 22),
                today: today
            )
        }
    }

    @Test func allowsTickingAPastDay() throws {
        let yesterday = WorkDay.empty(DayKey(year: 2026, month: 11, day: 12)).planning([a100])
        let ticked = try yesterday.settingCleaned(
            yesterday.entries[0].id,
            to: true,
            now: .warsaw(2026, 11, 13, 9),
            today: today
        )
        #expect(ticked.hasCleanedEntries)
    }

    @Test func refusesAnUnknownEntry() {
        #expect(throws: WorkDayError.entryNotFound) {
            try WorkDay.empty(today).settingCleaned(
                UUID(),
                to: true,
                now: .warsaw(2026, 11, 13, 9),
                today: today
            )
        }
    }

    @Test func totalsTheDay() throws {
        let now = Date.warsaw(2026, 11, 13, 10)
        let planned = WorkDay.empty(today).planning([a100, a101, a106])
        let day =
            try planned
            .settingCleaned(
                planned.entries[0].id,
                to: true,
                now: now,
                today: today
            )
            .settingCleaned(
                planned.entries[2].id,
                to: true,
                now: now,
                today: today
            )
        #expect(day.earned == Money(minorUnits: 8400))
        #expect(day.planned == Money(minorUnits: 11200))
        #expect(day.cleanedCount == 2)
        #expect(day.hasCleanedEntries)
        #expect(!WorkDay.empty(today).hasCleanedEntries)
    }

    @Test func aNewDayIsBlank() {
        #expect(WorkDay.empty(today).isBlank)
    }

    @Test func aDayWithAPlanIsNotBlank() {
        #expect(WorkDay.empty(today).planning([a100]).isBlank == false)
    }

    @Test func aDayWithOnlyAManualDurationIsNotBlank() {
        var day = WorkDay.empty(today)
        day.manualDuration = .seconds(3600)
        #expect(day.isBlank == false)
    }
}

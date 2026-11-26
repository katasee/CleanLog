import Foundation
import Testing

@testable import CleanLog

struct ApartmentDuplicatesTests {
    private let smallID = UUID.fixture(1)
    private let middleID = UUID.fixture(2)
    private let largeID = UUID.fixture(3)

    private func revision(
        _ name: String,
        id: UUID,
        changedOn day: Int,
        minorUnits: Int = 2800,
        createdOn creationDay: Int = 1
    ) -> Revision<Apartment> {
        Revision(
            value: Apartment(
                id: id,
                name: name,
                price: Money(minorUnits: minorUnits),
                accessCode: nil,
                isReportedSeparately: false,
                createdAt: .warsaw(2026, 11, creationDay)
            ),
            changedAt: .warsaw(2026, 11, day)
        )
    }

    @Test func noMergeWithoutDuplicates() {
        let apartments = [
            revision("100", id: smallID, changedOn: 2),
            revision("101", id: largeID, changedOn: 3),
        ]
        #expect(ApartmentDuplicates.merges(in: apartments).isEmpty)
    }

    @Test func theCopyChangedLastGivesItsValues() throws {
        var newer = revision("100 ", id: largeID, changedOn: 5, minorUnits: 3000)
        newer.value.isReportedSeparately = true
        newer.value.accessCode = "1234#"
        let older = revision("100", id: smallID, changedOn: 2)

        let merge = try #require(ApartmentDuplicates.merges(in: [older, newer]).first)

        #expect(merge.survivor.value.name == "100 ")
        #expect(merge.survivor.value.price == Money(minorUnits: 3000))
        #expect(merge.survivor.value.isReportedSeparately)
        #expect(merge.survivor.value.accessCode == "1234#")
        #expect(merge.survivor.changedAt == .warsaw(2026, 11, 5))
    }

    @Test(arguments: [2, 9])
    func theSmallestIDSurvives(largeChangedOn day: Int) throws {
        let apartments = [
            revision("100", id: largeID, changedOn: day),
            revision("100", id: smallID, changedOn: 5),
        ]

        let merge = try #require(ApartmentDuplicates.merges(in: apartments).first)

        #expect(merge.survivor.value.id == smallID)
        #expect(merge.removedIDs == [largeID])
    }

    @Test func keepsTheEarliestCreation() throws {
        let apartments = [
            revision("100", id: smallID, changedOn: 2, createdOn: 2),
            revision("100", id: largeID, changedOn: 5, createdOn: 1),
        ]

        let merge = try #require(ApartmentDuplicates.merges(in: apartments).first)

        #expect(merge.survivor.value.createdAt == .warsaw(2026, 11, 1))
    }

    @Test func mergesThreeCopies() throws {
        let apartments = [
            revision("6piw", id: middleID, changedOn: 3),
            revision("6Piw", id: largeID, changedOn: 4),
            revision(" 6PIW", id: smallID, changedOn: 2),
        ]

        let merges = ApartmentDuplicates.merges(in: apartments)

        #expect(merges.count == 1)
        let merge = try #require(merges.first)
        #expect(merge.survivor.value.id == smallID)
        #expect(merge.survivor.value.name == "6Piw")
        #expect(merge.removedIDs == [middleID, largeID])
    }

    @Test func mergesEachGroupInNameOrder() {
        let apartments = [
            revision("B", id: largeID, changedOn: 2),
            revision("a", id: middleID, changedOn: 2),
            revision("b", id: smallID, changedOn: 3),
            revision("A", id: .fixture(4), changedOn: 3),
        ]

        let names = ApartmentDuplicates.merges(in: apartments).map { ApartmentName.matchKey($0.survivor.value.name) }

        #expect(names == ["a", "b"])
    }

    @Test func draftValidationUsesTheSameMatch() {
        let existing = [Apartment.fixture("6piw")]
        let draft = ApartmentDraft(
            name: " 6PIW ",
            price: Money(minorUnits: 2800),
            accessCode: nil,
            isReportedSeparately: false
        )

        #expect(throws: ApartmentError.duplicateName) {
            try draft.validated(against: existing)
        }
    }
}

import Foundation
import Testing

@testable import CleanLog

struct ApartmentDraftTests {
    private let active = Apartment.fixture("101")
    private let archived = Apartment.fixture("205", archived: true)
    private var existing: [Apartment] { [active, archived] }

    private func draft(_ name: String, minorUnits: Int = 2800, code: String? = nil) -> ApartmentDraft {
        ApartmentDraft(
            name: name,
            price: Money(minorUnits: minorUnits),
            accessCode: code,
            isReportedSeparately: false
        )
    }

    @Test func trimsTheNameAndTheCode() throws {
        let result = try draft("  102 ", code: "  4821 ").validated(against: existing)
        #expect(result.name == "102")
        #expect(result.accessCode == "4821")
    }

    @Test(arguments: ["   ", ""])
    func storesABlankCodeAsNil(code: String) throws {
        #expect(try draft("102", code: code).validated(against: existing).accessCode == nil)
    }

    @Test func keepsAMissingCodeNil() throws {
        #expect(try draft("102").validated(against: existing).accessCode == nil)
    }

    @Test(arguments: ["", "   "])
    func rejectsAnEmptyName(name: String) {
        #expect(throws: ApartmentError.emptyName) {
            try draft(name).validated(against: existing)
        }
    }

    @Test(arguments: ["101", " 101 "])
    func rejectsADuplicateOfAnActiveApartment(name: String) {
        #expect(throws: ApartmentError.duplicateName) {
            try draft(name).validated(against: existing)
        }
    }

    @Test func comparesNamesCaseInsensitively() {
        #expect(throws: ApartmentError.duplicateName) {
            try draft("6PIW").validated(against: [.fixture("6piw")])
        }
    }

    @Test func allowsTheNameOfAnArchivedApartment() throws {
        #expect(try draft("205").validated(against: existing).name == "205")
    }

    @Test func allowsAnApartmentToKeepItsOwnName() throws {
        let edited = try ApartmentDraft(active).validated(against: existing, excluding: active.id)
        #expect(edited.name == "101")
    }

    @Test func rejectsANegativePrice() {
        #expect(throws: ApartmentError.negativePrice) {
            try draft("102", minorUnits: -1).validated(against: existing)
        }
    }

    @Test func allowsAFreeApartment() throws {
        #expect(try draft("102", minorUnits: 0).validated(against: existing).price == .zero)
    }

    @Test func createsAnActiveApartmentFromADraft() {
        let createdAt = Date.warsaw(2026, 11, 13, 9)
        let apartment = Apartment(
            draft("102", code: "4821"),
            sortOrder: 3,
            createdAt: createdAt
        )
        #expect(apartment.name == "102")
        #expect(apartment.accessCode == "4821")
        #expect(apartment.sortOrder == 3)
        #expect(apartment.isArchived == false)
        #expect(apartment.createdAt == createdAt)
    }

    @Test func applyingADraftChangesOnlyTheEditableFields() {
        let edited = archived.applying(
            draft(
                "206",
                minorUnits: 3000,
                code: "1#"
            )
        )
        #expect(edited.id == archived.id)
        #expect(edited.name == "206")
        #expect(edited.price == Money(minorUnits: 3000))
        #expect(edited.accessCode == "1#")
        #expect(edited.isArchived)
        #expect(edited.sortOrder == archived.sortOrder)
        #expect(edited.createdAt == archived.createdAt)
    }
}

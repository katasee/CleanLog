import Testing

@testable import CleanLog

struct ApartmentNameTests {
    @Test func namesMatchWithoutCaseAndSurroundingSpaces() {
        #expect(ApartmentName.matchKey(" 6Piw ") == ApartmentName.matchKey("6piw"))
        #expect(ApartmentName.matchKey("100\n") == ApartmentName.matchKey("100"))
    }

    @Test func innerSpacesStillCount() {
        #expect(ApartmentName.matchKey("100") != ApartmentName.matchKey("1 00"))
    }
}

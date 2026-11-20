import Foundation
import Testing

@testable import CleanLog

@Test func targetRuns() {
    #expect(Calendar.warsaw.timeZone.identifier == "Europe/Warsaw")
}

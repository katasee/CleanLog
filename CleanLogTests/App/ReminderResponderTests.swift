import Testing

@testable import CleanLog

struct ReminderResponderTests {
    private let november = MonthKey(year: 2026, month: 11)

    @Test
    func openStoresTheRequest() {
        let responder = ReminderResponder()
        responder.open(november)
        #expect(responder.requestedReport == november)
    }

    @Test
    func takingTheRequestClearsIt() {
        let responder = ReminderResponder()
        responder.open(november)
        #expect(responder.takeRequestedReport() == november)
        #expect(responder.requestedReport == nil)
    }

    @Test
    func startsWithNoRequest() {
        #expect(ReminderResponder().takeRequestedReport() == nil)
    }
}

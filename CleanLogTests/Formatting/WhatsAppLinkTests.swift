import Foundation
import Testing

@testable import CleanLog

struct WhatsAppLinkTests {
    @Test func encodesThePlusSign() {
        #expect(
            WhatsAppLink.url(for: "2.11-(54)=1+155").absoluteString
                == "whatsapp://send?text=2.11-%2854%29%3D1%2B155"
        )
    }

    @Test func encodesNewlinesAndCommas() {
        #expect(
            WhatsAppLink.url(for: "1.10-(54,96)=2\n\n5.10-155").absoluteString
                == "whatsapp://send?text=1.10-%2854%2C96%29%3D2%0A%0A5.10-155"
        )
    }

    @Test func keepsUnreservedCharacters() {
        #expect(
            WhatsAppLink.url(for: "6piw-133kol_a.b~").absoluteString
                == "whatsapp://send?text=6piw-133kol_a.b~"
        )
    }

    @Test func probeIsTheSendLink() {
        #expect(WhatsAppLink.probe.absoluteString == "whatsapp://send")
    }
}

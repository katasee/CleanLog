import CoreGraphics
import Testing

@testable import CleanLog

struct BackdropCircleTests {
    private let circle = BackdropCircle(
        tone: .glow,
        origin: CGPoint(x: 150, y: -100),
        diameter: 360,
        opacity: 0.55
    )

    @Test func keepsTheCanvasFrameAtTheReferenceSize() {
        let frame = circle.frame(in: CGSize(width: 390, height: 844))

        #expect(frame == CGRect(x: 150, y: -100, width: 360, height: 360))
    }

    @Test func scalesWithTheScreen() {
        let frame = circle.frame(in: CGSize(width: 780, height: 1688))

        #expect(frame == CGRect(x: 300, y: -200, width: 720, height: 720))
    }

    @Test func sizesByWidthAndPlacesVerticallyByHeight() {
        let frame = circle.frame(in: CGSize(width: 390, height: 422))

        #expect(frame == CGRect(x: 150, y: -50, width: 360, height: 360))
    }
}

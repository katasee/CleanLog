import CoreGraphics

struct BackdropCircle: Hashable {
    enum Tone: Hashable {
        case glow
        case mist
    }

    static let referenceSize = CGSize(width: 390, height: 844)

    let tone: Tone
    let origin: CGPoint
    let diameter: CGFloat
    let opacity: Double

    func frame(in size: CGSize) -> CGRect {
        let horizontalScale = size.width / Self.referenceSize.width
        let verticalScale = size.height / Self.referenceSize.height
        let scaledDiameter = diameter * horizontalScale
        return CGRect(
            x: origin.x * horizontalScale,
            y: origin.y * verticalScale,
            width: scaledDiameter,
            height: scaledDiameter
        )
    }
}

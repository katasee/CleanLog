import SwiftUI

private struct ScreenBackground: ViewModifier {
    private enum Layout {
        static let blurRadius: CGFloat = 70
    }

    let circles: [BackdropCircle]

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    Color.background
                    ForEach(circles, id: \.self) { circle in
                        let frame = circle.frame(in: proxy.size)
                        Circle()
                            .fill(circle.tone.color)
                            .opacity(circle.opacity)
                            .frame(width: frame.width, height: frame.height)
                            .offset(x: frame.minX, y: frame.minY)
                            .blur(radius: Layout.blurRadius)
                    }
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }
}

extension BackdropCircle.Tone {
    fileprivate var color: Color {
        switch self {
        case .glow: Color.backdropGlow
        case .mist: Color.backdropMist
        }
    }
}

extension View {
    func screenBackground(_ circles: [BackdropCircle]) -> some View {
        modifier(ScreenBackground(circles: circles))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        Text(verbatim: "Листопад")
            .font(.subheadline)
            .foregroundStyle(Color.inkSecondary)
        Text(verbatim: "1 876 zł")
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.ink)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .cardSurface()
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .screenBackground([
        BackdropCircle(
            tone: .glow,
            origin: CGPoint(x: 150, y: -100),
            diameter: 360,
            opacity: 0.55
        ),
        BackdropCircle(
            tone: .mist,
            origin: CGPoint(x: -150, y: 300),
            diameter: 320,
            opacity: 0.6
        ),
    ])
}

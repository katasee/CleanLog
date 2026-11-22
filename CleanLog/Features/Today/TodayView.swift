import SwiftUI

struct TodayView: View {
    private enum Layout {
        static let backdrop = [
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
        ]
    }

    var body: some View {
        NavigationStack {
            Color.clear
                .screenBackground(Layout.backdrop)
                .navigationTitle(Text(.tabTodayTitle))
        }
    }
}

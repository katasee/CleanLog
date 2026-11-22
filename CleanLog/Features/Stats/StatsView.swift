import SwiftUI

struct StatsView: View {
    private enum Layout {
        static let backdrop = [
            BackdropCircle(
                tone: .glow,
                origin: CGPoint(x: -110, y: -80),
                diameter: 340,
                opacity: 0.55
            ),
            BackdropCircle(
                tone: .mist,
                origin: CGPoint(x: 240, y: 420),
                diameter: 300,
                opacity: 0.6
            ),
        ]
    }

    var body: some View {
        NavigationStack {
            Color.clear
                .screenBackground(Layout.backdrop)
                .navigationTitle(Text(.tabStatsTitle))
        }
    }
}

import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            Color.background
                .ignoresSafeArea()
                .navigationTitle(Text(.tabStatsTitle))
        }
    }
}

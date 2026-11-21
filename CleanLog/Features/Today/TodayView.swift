import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Color.background
                .ignoresSafeArea()
                .navigationTitle(Text(.tabTodayTitle))
        }
    }
}

import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.today) {
                TodayView()
            } label: {
                Label {
                    Text(.tabTodayTitle)
                } icon: {
                    Image(systemName: "checkmark.circle")
                }
            }
            Tab(value: AppTab.stats) {
                StatsView()
            } label: {
                Label {
                    Text(.tabStatsTitle)
                } icon: {
                    Image(systemName: "chart.bar")
                }
            }
            Tab(value: AppTab.apartments) {
                ApartmentsView()
            } label: {
                Label {
                    Text(.tabApartmentsTitle)
                } icon: {
                    Image(systemName: "building.2")
                }
            }
        }
    }
}

#Preview {
    RootView()
}

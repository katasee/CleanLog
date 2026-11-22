import SwiftUI

private enum AppTab: Hashable {
    case today
    case stats
    case apartments
}

struct RootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .today) {
                TodayView()
            } label: {
                Label {
                    Text(.tabTodayTitle)
                } icon: {
                    Image(systemName: "checkmark.circle")
                }
            }
            Tab(value: .stats) {
                StatsView()
            } label: {
                Label {
                    Text(.tabStatsTitle)
                } icon: {
                    Image(systemName: "chart.bar")
                }
            }
            Tab(value: .apartments) {
                ApartmentsView(repository: dependencies.apartments)
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

#if DEBUG
    #Preview {
        RootView()
            .environment(AppDependencies.preview())
    }
#endif

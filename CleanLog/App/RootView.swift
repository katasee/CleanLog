import SwiftUI

private enum AppTab: Hashable {
    case today
    case stats
    case apartments
}

private struct RootReportRoute: Identifiable {
    let month: MonthKey
    let today: DayKey

    var id: MonthKey { month }
}

struct RootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .today
    @State private var reminderMonth = DayKey(.now, calendar: .current).monthKey
    @State private var report: RootReportRoute?

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
                StatsView(dependencies: dependencies)
            } label: {
                Label {
                    Text(.tabStatsTitle)
                } icon: {
                    Image(systemName: "chart.bar")
                }
            }
            Tab(value: .apartments) {
                ApartmentsView(dependencies: dependencies)
            } label: {
                Label {
                    Text(.tabApartmentsTitle)
                } icon: {
                    Image(systemName: "building.2")
                }
            }
        }
        .sheet(item: $report) { report in
            ReportView(
                month: report.month,
                today: report.today,
                dependencies: dependencies
            )
        }
        .task {
            await dependencies.reminderScheduler.observeSettings()
        }
        .task(id: reminderMonth) {
            await dependencies.reminderScheduler.observeDays(in: reminderMonth)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                rereadReminderMonth()
            }
        }
        .onChange(of: dependencies.reminderResponder.requestedReport, initial: true) {
            openRequestedReport()
        }
    }

    private func rereadReminderMonth() {
        reminderMonth = DayKey(.now, calendar: .current).monthKey
    }

    private func openRequestedReport() {
        guard let month = dependencies.reminderResponder.takeRequestedReport() else { return }
        selectedTab = .stats
        report = RootReportRoute(
            month: month,
            today: DayKey(.now, calendar: .current)
        )
    }
}

#if DEBUG
    #Preview {
        RootView()
            .environment(AppDependencies.preview())
    }
#endif

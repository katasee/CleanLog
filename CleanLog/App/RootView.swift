import SwiftUI

private enum AppTab: Hashable {
    case today
    case stats
    case apartments
}

private struct MonthEndReminderRunner: ViewModifier {
    let scheduler: MonthEndReminderScheduler
    @Environment(\.scenePhase) private var scenePhase
    @State private var month = DayKey(.now, calendar: .current).monthKey

    func body(content: Content) -> some View {
        content
            .task {
                await scheduler.observeSettings()
            }
            .task(id: month) {
                await scheduler.observeDays(in: month)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    rereadMonth()
                }
            }
    }

    private func rereadMonth() {
        month = DayKey(.now, calendar: .current).monthKey
    }
}

struct RootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var selectedTab: AppTab = .today
    @State private var report: ReportRoute?
    @State private var pendingReport: ReportRoute?

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
        .modifier(MonthEndReminderRunner(scheduler: dependencies.reminderScheduler))
        .onChange(of: dependencies.reminderResponder.requestedReport, initial: true) {
            openRequestedReport()
        }
        .onChange(of: selectedTab) {
            presentPendingReport()
        }
    }

    private func openRequestedReport() {
        guard let month = dependencies.reminderResponder.takeRequestedReport() else { return }
        pendingReport = ReportRoute(
            month: month,
            today: DayKey(.now, calendar: .current)
        )
        if selectedTab == .stats {
            presentPendingReport()
        } else {
            selectedTab = .stats
        }
    }

    private func presentPendingReport() {
        guard let pendingReport else { return }
        report = pendingReport
        self.pendingReport = nil
    }
}

#if DEBUG
    #Preview {
        RootView()
            .environment(AppDependencies.preview())
    }
#endif

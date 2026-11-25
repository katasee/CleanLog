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

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection = TodaySelection(today: DayKey(.now, calendar: .current))
    @State private var isShowingCalendar = false

    var body: some View {
        NavigationStack {
            DayView(
                day: selection.day,
                today: selection.today,
                dependencies: dependencies,
                onStep: step,
                onShowToday: showToday,
                onShowCalendar: showCalendar
            )
            .id(selection)
            .screenBackground(Layout.backdrop)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingCalendar) {
                CalendarView(
                    selected: selection.day,
                    today: selection.today,
                    workDays: dependencies.workDays,
                    onOpenDay: openDay
                )
            }
        }
        .task {
            await advanceAtEachMidnight()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                advanceToCurrentDay()
            }
        }
    }

    private func step(by days: Int) {
        selection.step(by: days, calendar: .current)
    }

    private func showToday() {
        selection.showToday()
    }

    private func showCalendar() {
        isShowingCalendar = true
    }

    private func openDay(_ day: DayKey) {
        selection.show(day)
    }

    private func advanceAtEachMidnight() async {
        while true {
            let untilNextDay = TodaySelection.timeUntilNextDay(after: .now, calendar: .current)
            guard (try? await Task.sleep(for: untilNextDay)) != nil else { return }
            advanceToCurrentDay()
        }
    }

    private func advanceToCurrentDay() {
        selection.advance(to: DayKey(.now, calendar: .current))
    }
}

#if DEBUG
    #Preview {
        TodayView()
            .environment(
                TodayPreviewData.dependencies([
                    TodayPreviewData.day(sessions: [TodayPreviewData.session(startedHoursAgo: 2)])
                ])
            )
    }
#endif

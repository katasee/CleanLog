import SwiftUI

struct DayView: View {
    private enum Layout {
        static let cardInsets = EdgeInsets(
            top: 8,
            leading: 0,
            bottom: 8,
            trailing: 0
        )
    }

    @State private var viewModel: DayViewModel
    @State private var isEditingDuration = false

    private let onStep: (Int) -> Void
    private let onShowToday: () -> Void

    init(
        day: DayKey,
        today: DayKey,
        dependencies: AppDependencies,
        onStep: @escaping (Int) -> Void,
        onShowToday: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: DayViewModel(
                day: day,
                today: today,
                workDays: dependencies.workDays,
                apartments: dependencies.apartments
            )
        )
        self.onStep = onStep
        self.onShowToday = onShowToday
    }

    var body: some View {
        List {
            Section {
                DayHeaderView(
                    header: viewModel.header,
                    onStep: onStep,
                    onShowToday: onShowToday
                )
                .modifier(CardRow(insets: Layout.cardInsets))
                if let timer = viewModel.timer {
                    TimerCardView(
                        viewModel: viewModel,
                        timer: timer,
                        onEditDuration: editDuration
                    )
                    .modifier(CardRow(insets: Layout.cardInsets))
                }
                if let summary = viewModel.summary {
                    DaySummaryView(summary: summary)
                        .modifier(CardRow(insets: Layout.cardInsets))
                }
                if viewModel.showsEmptyState {
                    EmptyDayView(viewModel: viewModel)
                        .modifier(CardRow(insets: Layout.cardInsets))
                }
            }
            if !viewModel.rows.isEmpty {
                DayListView(viewModel: viewModel)
            }
        }
        .scrollContentBackground(.hidden)
        .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}
        .sheet(isPresented: $isEditingDuration) {
            ManualDurationSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.observe()
        }
    }

    private func editDuration() {
        isEditingDuration = true
    }
}

private struct CardRow: ViewModifier {
    let insets: EdgeInsets

    func body(content: Content) -> some View {
        content
            .listRowInsets(insets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

#if DEBUG
    #Preview("Running") {
        DayView(
            day: TodayPreviewData.today,
            today: TodayPreviewData.today,
            dependencies: TodayPreviewData.dependencies([
                TodayPreviewData.day(sessions: [TodayPreviewData.session(startedHoursAgo: 4.2)])
            ]),
            onStep: { _ in },
            onShowToday: {}
        )
        .background(Color.background)
    }

    #Preview("Past") {
        let yesterday = TodayPreviewData.today.adding(days: -1, calendar: .current)
        DayView(
            day: yesterday,
            today: TodayPreviewData.today,
            dependencies: TodayPreviewData.dependencies([
                TodayPreviewData.day(
                    yesterday,
                    sessions: [
                        TodayPreviewData.session(startedHoursAgo: 30, endedHoursAgo: 28),
                        TodayPreviewData.session(startedHoursAgo: 27.5, endedHoursAgo: 25),
                    ],
                    isTimerFinished: true
                )
            ]),
            onStep: { _ in },
            onShowToday: {}
        )
        .background(Color.background)
    }

    #Preview("Empty") {
        DayView(
            day: TodayPreviewData.today,
            today: TodayPreviewData.today,
            dependencies: TodayPreviewData.dependencies([
                TodayPreviewData.day(TodayPreviewData.today.adding(days: -1, calendar: .current))
            ]),
            onStep: { _ in },
            onShowToday: {}
        )
        .background(Color.background)
    }

    #Preview("Future") {
        let tomorrow = TodayPreviewData.today.adding(days: 1, calendar: .current)
        DayView(
            day: tomorrow,
            today: TodayPreviewData.today,
            dependencies: TodayPreviewData.dependencies([TodayPreviewData.day(tomorrow)]),
            onStep: { _ in },
            onShowToday: {}
        )
        .background(Color.background)
    }
#endif

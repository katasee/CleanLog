import SwiftUI

struct TimerCardView: View {
    private enum Layout {
        static let spacing: CGFloat = 12
        static let textSpacing: CGFloat = 2
    }

    let viewModel: DayViewModel
    let timer: DayTimer

    var body: some View {
        HStack(spacing: Layout.spacing) {
            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                TimerStatus(timer: timer)
                TimerClock(viewModel: viewModel, timer: timer)
                TimerNotes(timer: timer, droppedNote: viewModel.droppedNote)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            TimerControls(viewModel: viewModel, timer: timer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

private struct TimerStatus: View {
    private enum Layout {
        static let spacing: CGFloat = 6
        static let dotDiameter: CGFloat = 7
    }

    let timer: DayTimer

    var body: some View {
        HStack(spacing: Layout.spacing) {
            switch timer {
            case .running(let status):
                StatusDot(color: Color.accentColor, diameter: Layout.dotDiameter)
                Text(verbatim: status)
                    .foregroundStyle(Color.accentColor)
            case .paused:
                StatusDot(color: Color.warning, diameter: Layout.dotDiameter)
                Text(.todayTimerPaused)
                    .foregroundStyle(Color.warning)
            case .idle, .finished, .past:
                Text(.todayTimerTitle)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .font(.footnote.weight(.semibold))
    }
}

private struct StatusDot: View {
    let color: Color
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

private struct TimerClock: View {
    let viewModel: DayViewModel
    let timer: DayTimer

    var body: some View {
        switch timer {
        case .running:
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ClockText(text: viewModel.timerText(at: context.date), color: Color.ink)
            }
        case .paused:
            ClockText(text: viewModel.timerText(at: .now), color: Color.ink)
        case .idle:
            ClockText(text: viewModel.timerText(at: .now), color: Color.inkSecondary)
        case .finished(let total, _), .past(let total, _):
            ClockText(text: total, color: Color.ink)
        }
    }
}

private struct ClockText: View {
    let text: String
    let color: Color

    var body: some View {
        Text(verbatim: text)
            .font(.largeTitle.weight(.semibold))
            .fontDesign(.rounded)
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

private struct TimerNotes: View {
    let timer: DayTimer
    let droppedNote: String?

    var body: some View {
        switch timer {
        case .finished(_, let span?), .past(_, let span?):
            NoteText(text: span, color: Color.inkSecondary)
        case .idle, .running, .paused, .finished, .past:
            EmptyView()
        }
        if let droppedNote {
            NoteText(text: droppedNote, color: Color.warning)
        }
    }
}

private struct NoteText: View {
    let text: String
    let color: Color

    var body: some View {
        Text(verbatim: text)
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

private struct TimerControls: View {
    private enum Layout {
        static let spacing: CGFloat = 10
    }

    let viewModel: DayViewModel
    let timer: DayTimer

    var body: some View {
        HStack(spacing: Layout.spacing) {
            switch timer {
            case .idle:
                TextButton(title: .todayTimerStart) { await viewModel.startTimer() }
            case .running:
                GlassRoundButton(systemImage: "pause.fill", label: .todayTimerPause) { await viewModel.pauseTimer() }
                StopButton { await viewModel.finishTimer() }
            case .paused:
                GlassRoundButton(systemImage: "play.fill", label: .todayTimerResume) { await viewModel.startTimer() }
                StopButton { await viewModel.finishTimer() }
            case .finished:
                TextButton(title: .todayTimerContinue) { await viewModel.startTimer() }
            case .past:
                EmptyView()
            }
        }
    }
}

private struct TextButton: View {
    let title: LocalizedStringResource
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Text(title)
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }
}

private struct GlassRoundButton: View {
    let systemImage: String
    let label: LocalizedStringResource
    let action: () async -> Void

    @ScaledMetric(relativeTo: .title3) private var diameter = TimerButtonLayout.diameter

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.ink)
                .frame(width: diameter, height: diameter)
                .glassSurface(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

private struct StopButton: View {
    let action: () async -> Void

    @ScaledMetric(relativeTo: .title3) private var diameter = TimerButtonLayout.diameter

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: "stop.fill")
                .font(.title3)
                .frame(width: diameter, height: diameter)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .accessibilityLabel(Text(.todayTimerStop))
    }
}

private enum TimerButtonLayout {
    static let diameter: CGFloat = 52
}

#if DEBUG
    private struct TimerCardPreview: View {
        @State private var viewModel: DayViewModel

        init(_ workDay: WorkDay) {
            _viewModel = State(
                initialValue: DayViewModel(
                    day: workDay.day,
                    today: TodayPreviewData.today,
                    workDays: FakeWorkDayRepository([workDay]),
                    apartments: FakeApartmentRepository()
                )
            )
        }

        var body: some View {
            Group {
                if let timer = viewModel.timer {
                    TimerCardView(viewModel: viewModel, timer: timer)
                }
            }
            .task {
                await viewModel.observe()
            }
        }
    }

    #Preview {
        let ended = TodayPreviewData.session(startedHoursAgo: 3, endedHoursAgo: 1)
        ScrollView {
            VStack(spacing: 16) {
                TimerCardPreview(TodayPreviewData.day())
                TimerCardPreview(TodayPreviewData.day(sessions: [TodayPreviewData.session(startedHoursAgo: 2)]))
                TimerCardPreview(TodayPreviewData.day(sessions: [ended]))
                TimerCardPreview(TodayPreviewData.day(sessions: [ended], isTimerFinished: true))
                TimerCardPreview(TodayPreviewData.day(TodayPreviewData.today.adding(days: -1, calendar: .current)))
            }
            .padding()
        }
        .background(Color.background)
    }
#endif

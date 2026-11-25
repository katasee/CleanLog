import SwiftUI

private struct ShowTodayButton: View {
    private enum Layout {
        static let target: CGFloat = 44
        static let padding = EdgeInsets(
            top: 10,
            leading: 16,
            bottom: 10,
            trailing: 16
        )
    }

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(.todayHeaderShowToday)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink)
                .padding(Layout.padding)
                .frame(minHeight: Layout.target)
                .glassSurface(.capsule)
        }
        .buttonStyle(.plain)
    }
}

struct DayHeaderView: View {
    private enum Layout {
        static let titleSpacing: CGFloat = 2
        static let stepSpacing: CGFloat = 0
        static let actionSpacing: CGFloat = 8
    }

    let header: DayHeader
    let onStep: (Int) -> Void
    let onShowToday: () -> Void
    let onShowCalendar: () -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: Layout.titleSpacing) {
                HStack(spacing: Layout.stepSpacing) {
                    StepButton(
                        systemImage: "chevron.left",
                        label: .todayHeaderPrevious,
                        action: stepBack
                    )
                    Text(verbatim: header.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.inkSecondary)
                    StepButton(
                        systemImage: "chevron.right",
                        label: .todayHeaderNext,
                        action: stepForward
                    )
                }
                Text(verbatim: header.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            HStack(spacing: Layout.actionSpacing) {
                if !header.isToday {
                    ShowTodayButton(action: onShowToday)
                }
                GlassIconButton(
                    systemImage: "calendar",
                    label: .todayHeaderCalendar,
                    action: onShowCalendar
                )
            }
        }
    }

    private func stepBack() {
        onStep(-1)
    }

    private func stepForward() {
        onStep(1)
    }
}

#if DEBUG
    #Preview {
        VStack(spacing: 32) {
            DayHeaderView(
                header: DayHeader(
                    day: TodayPreviewData.today,
                    kind: .today,
                    calendar: .current,
                    locale: .current
                ),
                onStep: { _ in },
                onShowToday: {},
                onShowCalendar: {}
            )
            DayHeaderView(
                header: DayHeader(
                    day: TodayPreviewData.today.adding(days: -1, calendar: .current),
                    kind: .past,
                    calendar: .current,
                    locale: .current
                ),
                onStep: { _ in },
                onShowToday: {},
                onShowCalendar: {}
            )
        }
        .padding()
        .background(Color.background)
    }
#endif

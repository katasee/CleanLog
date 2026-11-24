import SwiftUI

struct CalendarView: View {
    private enum Layout {
        static let margin: CGFloat = 18
        static let spacing: CGFloat = 14
        static let backdrop = [
            BackdropCircle(
                tone: .glow,
                origin: CGPoint(x: 170, y: -90),
                diameter: 340,
                opacity: 0.55
            ),
            BackdropCircle(
                tone: .mist,
                origin: CGPoint(x: -140, y: 420),
                diameter: 300,
                opacity: 0.6
            ),
        ]
    }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CalendarViewModel

    private let onOpenDay: (DayKey) -> Void

    init(
        selected: DayKey,
        today: DayKey,
        workDays: any WorkDayRepository,
        onOpenDay: @escaping (DayKey) -> Void
    ) {
        self.init(
            viewModel: CalendarViewModel(
                selected: selected,
                today: today,
                workDays: workDays
            ),
            onOpenDay: onOpenDay
        )
    }

    init(viewModel: CalendarViewModel, onOpenDay: @escaping (DayKey) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenDay = onOpenDay
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.spacing) {
                CalendarHeader(
                    monthTitle: viewModel.monthTitle,
                    onClose: close,
                    onPrevious: viewModel.showPreviousMonth,
                    onNext: viewModel.showNextMonth
                )
                CalendarQuickPicks(picks: viewModel.quickPicks, onSelect: viewModel.select)
                CalendarGrid(
                    weekdaySymbols: viewModel.weekdaySymbols,
                    weeks: viewModel.weeks,
                    onSelect: viewModel.select
                )
            }
            .padding(Layout.margin)
        }
        .safeAreaInset(edge: .bottom) {
            CalendarDayCardView(card: viewModel.card, onOpen: openDay)
                .padding(Layout.margin)
        }
        .screenBackground(Layout.backdrop)
        .task(id: viewModel.shownMonth) {
            await viewModel.observeMonth()
        }
        .task(id: viewModel.selected) {
            await viewModel.observeSelectedDay()
        }
    }

    private func close() {
        dismiss()
    }

    private func openDay() {
        onOpenDay(viewModel.selected)
        dismiss()
    }
}

private struct CalendarHeader: View {
    private enum Layout {
        static let target: CGFloat = 44
        static let pagerSpacing: CGFloat = 2
    }

    let monthTitle: String
    let onClose: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            GlassIconButton(
                systemImage: "xmark",
                label: .calendarActionClose,
                action: onClose
            )
            Spacer(minLength: 0)
            HStack(spacing: Layout.pagerSpacing) {
                StepButton(
                    systemImage: "chevron.left",
                    label: .calendarMonthPrevious,
                    action: onPrevious
                )
                Text(verbatim: monthTitle)
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                StepButton(
                    systemImage: "chevron.right",
                    label: .calendarMonthNext,
                    action: onNext
                )
            }
            Spacer(minLength: 0)
            Color.clear
                .frame(width: Layout.target, height: Layout.target)
                .accessibilityHidden(true)
        }
    }
}

private struct CalendarQuickPicks: View {
    private enum Layout {
        static let spacing: CGFloat = 8
    }

    let picks: [CalendarQuickPick]
    let onSelect: (DayKey) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Layout.spacing) {
                buttons
            }
            VStack(spacing: Layout.spacing) {
                buttons
            }
        }
    }

    private var buttons: some View {
        ForEach(picks) { pick in
            CalendarQuickPickButton(pick: pick, onSelect: onSelect)
        }
    }
}

private struct CalendarQuickPickButton: View {
    private enum Layout {
        static let minHeight: CGFloat = 44
        static let horizontalPadding: CGFloat = 12
    }

    let pick: CalendarQuickPick
    let onSelect: (DayKey) -> Void

    var body: some View {
        Button(action: select) {
            Text(verbatim: pick.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(pick.isSelected ? Color.accent : Color.ink)
                .padding(.horizontal, Layout.horizontalPadding)
                .frame(maxWidth: .infinity, minHeight: Layout.minHeight)
                .modifier(QuickPickSurface(isSelected: pick.isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(pick.isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: pick.isSelected)
    }

    private func select() {
        onSelect(pick.day)
    }
}

private struct QuickPickSurface: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content.background(Color.accentSoft, in: .capsule)
        } else {
            content.glassSurface(.capsule)
        }
    }
}

private struct CalendarGrid: View {
    private enum Layout {
        static let rowSpacing: CGFloat = 4
        static let weekdayPadding: CGFloat = 6
    }

    let weekdaySymbols: [String]
    let weeks: [[CalendarCell?]]
    let onSelect: (DayKey) -> Void

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: Layout.rowSpacing) {
            GridRow {
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(verbatim: weekdaySymbols[index])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Layout.weekdayPadding)
                }
            }
            .accessibilityHidden(true)
            ForEach(weeks.indices, id: \.self) { weekIndex in
                GridRow {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        if let cell = weeks[weekIndex][dayIndex] {
                            CalendarCellView(cell: cell, onSelect: onSelect)
                        } else {
                            Color.clear
                                .gridCellUnsizedAxes([.horizontal, .vertical])
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .cardSurface()
    }
}

private struct CalendarCellView: View {
    private enum Layout {
        static let height: CGFloat = 52
        static let maxWidth: CGFloat = 46
        static let cornerRadius: CGFloat = 16
        static let ringWidth: CGFloat = 2
        static let textSpacing: CGFloat = 1
        static let amountMinimumScale: CGFloat = 0.7
    }

    let cell: CalendarCell
    let onSelect: (DayKey) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var height = Layout.height
    @ScaledMetric(relativeTo: .body) private var maxWidth = Layout.maxWidth

    var body: some View {
        Button(action: select) {
            VStack(spacing: Layout.textSpacing) {
                Text(verbatim: cell.numberText)
                    .font(.body.weight(cell.isToday || cell.isSelected ? .bold : .medium))
                if let amountText = cell.amountText, !dynamicTypeSize.isAccessibilitySize {
                    Text(verbatim: amountText)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(Layout.amountMinimumScale)
                }
            }
            .monospacedDigit()
            .foregroundStyle(foreground)
            .frame(maxWidth: maxWidth, minHeight: height)
            .background(cell.isSelected ? Color.accent : Color.clear, in: .rect(cornerRadius: Layout.cornerRadius))
            .overlay {
                if cell.isToday && !cell.isSelected {
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .strokeBorder(Color.accent, lineWidth: Layout.ringWidth)
                }
            }
            .contentShape(.rect(cornerRadius: Layout.cornerRadius))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: cell.accessibilityLabel))
        .accessibilityAddTraits(cell.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var foreground: Color {
        if cell.isSelected {
            return Color.onAccent
        }
        return cell.isToday ? Color.accent : Color.ink
    }

    private func select() {
        onSelect(cell.day)
    }
}

private struct CalendarDayCardView: View {
    private enum Layout {
        static let spacing: CGFloat = 12
        static let placeholder = CalendarDayCard(
            weekdayText: " ",
            dateText: " ",
            summaryText: " "
        )
    }

    let card: CalendarDayCard?
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: Layout.spacing) {
            CalendarDayCardText(card: card ?? Layout.placeholder)
                .opacity(card == nil ? 0 : 1)
                .animation(.default, value: card)
            Button(action: onOpen) {
                Text(.calendarActionOpen)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .cardSurface()
    }
}

private struct CalendarDayCardText: View {
    private enum Layout {
        static let textSpacing: CGFloat = 2
    }

    let card: CalendarDayCard

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .lastTextBaseline) {
                dateLines
                Spacer(minLength: 0)
                summary
            }
            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                dateLines
                summary
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var dateLines: some View {
        VStack(alignment: .leading, spacing: Layout.textSpacing) {
            Text(verbatim: card.weekdayText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.inkSecondary)
            Text(verbatim: card.dateText)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.ink)
        }
    }

    private var summary: some View {
        Text(verbatim: card.summaryText)
            .font(.headline)
            .monospacedDigit()
            .foregroundStyle(Color.ink)
    }
}

#if DEBUG
    #Preview("This month") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                CalendarView(
                    selected: CalendarPreviewData.today,
                    today: CalendarPreviewData.today,
                    workDays: CalendarPreviewData.workDays(),
                    onOpenDay: { _ in }
                )
            }
    }

    #Preview("Empty") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                CalendarView(
                    selected: CalendarPreviewData.today,
                    today: CalendarPreviewData.today,
                    workDays: FakeWorkDayRepository(),
                    onOpenDay: { _ in }
                )
            }
    }
#endif

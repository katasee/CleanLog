import SwiftUI

struct StatsView: View {
    private enum Layout {
        static let margin: CGFloat = 20
        static let spacing: CGFloat = 16
        static let backdrop = [
            BackdropCircle(
                tone: .glow,
                origin: CGPoint(x: -110, y: -80),
                diameter: 340,
                opacity: 0.55
            ),
            BackdropCircle(
                tone: .mist,
                origin: CGPoint(x: 240, y: 420),
                diameter: 300,
                opacity: 0.6
            ),
        ]
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: StatsViewModel
    @State private var report: StatsReportRoute?

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        _viewModel = State(
            initialValue: StatsViewModel(
                today: DayKey(.now, calendar: .current),
                workDays: dependencies.workDays
            )
        )
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.spacing) {
                    StatsMonthSwitcher(
                        monthTitle: viewModel.monthTitle,
                        canShowNextMonth: viewModel.canShowNextMonth,
                        onPrevious: viewModel.showPreviousMonth,
                        onNext: viewModel.showNextMonth
                    )
                    StatsEarningsCard(summary: viewModel.summary)
                    StatsValueCards(summary: viewModel.summary)
                    StatsTopApartments(summary: viewModel.summary)
                }
                .padding(Layout.margin)
            }
            .screenBackground(Layout.backdrop)
            .navigationTitle(Text(.tabStatsTitle))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StatsReportButton(
                        isEnabled: viewModel.summary.hasCleanedApartments,
                        action: openReport
                    )
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
        .task(id: viewModel.shownMonth) {
            await viewModel.observeMonth()
        }
        .task(id: viewModel.shownMonth) {
            await viewModel.observePreviousMonth()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                advanceToCurrentDay()
            }
        }
    }

    private func advanceToCurrentDay() {
        viewModel.advance(to: DayKey(.now, calendar: .current))
    }

    private func openReport() {
        report = StatsReportRoute(
            month: viewModel.shownMonth,
            today: DayKey(.now, calendar: .current)
        )
    }
}

private struct StatsReportRoute: Identifiable {
    let month: MonthKey
    let today: DayKey

    var id: MonthKey { month }
}

private struct StatsReportButton: View {
    private enum Layout {
        static let spacing: CGFloat = 6
    }

    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.spacing) {
                Image(systemName: "square.and.arrow.up")
                Text(.statsActionReport)
            }
        }
        .disabled(!isEnabled)
    }
}

private struct StatsMonthSwitcher: View {
    private enum Layout {
        static let spacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 4
    }

    let monthTitle: String
    let canShowNextMonth: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: Layout.spacing) {
            StepButton(
                systemImage: "chevron.left",
                label: .statsMonthPrevious,
                action: onPrevious
            )
            Text(verbatim: monthTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            StepButton(
                systemImage: "chevron.right",
                label: .statsMonthNext,
                action: onNext
            )
            .disabled(!canShowNextMonth)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .glassSurface(.capsule)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

private struct StatsEarningsCard: View {
    private enum Layout {
        static let spacing: CGFloat = 10
        static let textSpacing: CGFloat = 2
        static let amountMinimumScale: CGFloat = 0.5
    }

    let summary: StatsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                Text(.statsEarnedTitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.inkSecondary)
                Text(verbatim: summary.earnedText)
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.amountMinimumScale)
            }
            if let changeText = summary.changeText {
                Badge(text: changeText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

private struct StatsValueCards: View {
    private enum Layout {
        static let spacing: CGFloat = 12
    }

    let summary: StatsSummary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: Layout.spacing) {
            rowLayout {
                StatsValueCard(title: .statsCardCleaned, value: summary.cleanedText)
                StatsValueCard(title: .statsCardWorked, value: summary.workedText)
            }
            rowLayout {
                StatsValueCard(title: .statsCardPerHour, value: summary.perHourText)
                StatsValueCard(title: .statsCardPerDay, value: summary.perDayText)
            }
        }
    }

    private var rowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Layout.spacing))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Layout.spacing))
    }
}

private struct StatsValueCard: View {
    private enum Layout {
        static let spacing: CGFloat = 4
    }

    let title: LocalizedStringResource
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.inkSecondary)
            Text(verbatim: value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

private struct StatsTopApartments: View {
    private enum Layout {
        static let spacing: CGFloat = 8
        static let headingPadding: CGFloat = 6
    }

    let summary: StatsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            StatsTopHeading(workingDaysText: summary.workingDaysText)
                .padding(.horizontal, Layout.headingPadding)
            if summary.hasCleanedApartments {
                StatsApartmentList(rows: summary.topApartments)
            } else {
                Text(.statsEmpty)
                    .font(.body)
                    .foregroundStyle(Color.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardSurface()
            }
        }
    }
}

private struct StatsTopHeading: View {
    let workingDaysText: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                StatsTopTitle()
                Spacer(minLength: 0)
                StatsWorkingDays(text: workingDaysText)
            }
            VStack(alignment: .leading) {
                StatsTopTitle()
                StatsWorkingDays(text: workingDaysText)
            }
        }
    }
}

private struct StatsTopTitle: View {
    var body: some View {
        Text(.statsTopTitle)
            .font(.title3.weight(.bold))
            .foregroundStyle(Color.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct StatsWorkingDays: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(Color.inkSecondary)
    }
}

private struct StatsApartmentList: View {
    let rows: [StatsApartmentRow]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                if row.id != rows.first?.id {
                    Divider().overlay(Color.hairline)
                }
                StatsApartmentRowView(row: row)
            }
        }
        .cardSurface()
    }
}

private struct StatsApartmentRowView: View {
    private enum Layout {
        static let spacing: CGFloat = 12
        static let minHeight: CGFloat = 44
        static let nameWidth: CGFloat = 64
        static let countWidth: CGFloat = 64
    }

    let row: StatsApartmentRow

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var nameWidth = Layout.nameWidth
    @ScaledMetric(relativeTo: .subheadline) private var countWidth = Layout.countWidth

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Layout.spacing) {
                    HStack(alignment: .firstTextBaseline) {
                        StatsApartmentName(name: row.name)
                        Spacer(minLength: 0)
                        StatsApartmentCount(text: row.countText)
                    }
                    StatsBar(fraction: row.barFraction)
                }
            } else {
                HStack(spacing: Layout.spacing) {
                    StatsApartmentName(name: row.name)
                        .frame(minWidth: nameWidth, alignment: .leading)
                    StatsBar(fraction: row.barFraction)
                    StatsApartmentCount(text: row.countText)
                        .frame(minWidth: countWidth, alignment: .trailing)
                }
            }
        }
        .frame(minHeight: Layout.minHeight)
        .accessibilityElement(children: .combine)
    }
}

private struct StatsApartmentName: View {
    let name: String

    var body: some View {
        Text(verbatim: name)
            .font(.headline)
            .foregroundStyle(Color.ink)
    }
}

private struct StatsApartmentCount: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(Color.inkSecondary)
    }
}

private struct StatsBar: View {
    private enum Layout {
        static let height: CGFloat = 8
    }

    let fraction: Double

    var body: some View {
        Capsule()
            .fill(Color.accentSoft)
            .frame(height: Layout.height)
            .overlay {
                Capsule()
                    .fill(Color.accent)
                    .visualEffect { [fraction] content, proxy in
                        content.offset(x: -proxy.size.width * (1 - fraction))
                    }
            }
            .clipShape(.capsule)
            .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview("Light") {
        StatsView(dependencies: .preview(workDays: StatsPreviewData.workDays()))
    }

    #Preview("Dark") {
        StatsView(dependencies: .preview(workDays: StatsPreviewData.workDays()))
            .preferredColorScheme(.dark)
    }

    #Preview("Empty") {
        StatsView(dependencies: .preview())
    }
#endif

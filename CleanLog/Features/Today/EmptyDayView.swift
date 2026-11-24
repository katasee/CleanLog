import SwiftUI

struct EmptyDayView: View {
    private enum Layout {
        static let spacing: CGFloat = 16
        static let iconCircleDiameter: CGFloat = 72
        static let verticalPadding: CGFloat = 14
    }

    let viewModel: DayViewModel
    let onAddApartments: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var iconCircleDiameter = Layout.iconCircleDiameter

    var body: some View {
        VStack(spacing: Layout.spacing) {
            Image(systemName: "list.clipboard")
                .font(.largeTitle)
                .foregroundStyle(Color.accent)
                .frame(width: iconCircleDiameter, height: iconCircleDiameter)
                .background(Color.accentSoft, in: .circle)
                .accessibilityHidden(true)
            Text(verbatim: viewModel.emptyTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            AddApartmentsButton(action: onAddApartments)
            if let copyOffer = viewModel.copyOffer {
                CopyPlanButton(title: copyOffer.text, action: copyPlan)
            }
        }
        .padding(.vertical, Layout.verticalPadding)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }

    private func copyPlan() {
        Task { await viewModel.copyPlan() }
    }
}

private struct AddApartmentsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(.todayEmptyAdd)
            } icon: {
                Image(systemName: "plus")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

private struct CopyPlanButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(verbatim: title)
            } icon: {
                Image(systemName: "arrow.counterclockwise")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

#if DEBUG
    private struct EmptyDayPreview: View {
        @State private var viewModel: DayViewModel

        init(day: DayKey, earlierDays: [WorkDay]) {
            _viewModel = State(
                initialValue: DayViewModel(
                    day: day,
                    today: TodayPreviewData.today,
                    workDays: FakeWorkDayRepository(earlierDays),
                    apartments: FakeApartmentRepository(TodayPreviewData.template)
                )
            )
        }

        var body: some View {
            EmptyDayView(viewModel: viewModel, onAddApartments: {})
                .task {
                    await viewModel.observe()
                }
        }
    }

    #Preview {
        let yesterday = TodayPreviewData.today.adding(days: -1, calendar: .current)
        let twoDaysAgo = TodayPreviewData.today.adding(days: -2, calendar: .current)
        ScrollView {
            VStack(spacing: 16) {
                EmptyDayPreview(day: TodayPreviewData.today, earlierDays: [TodayPreviewData.day(twoDaysAgo)])
                EmptyDayPreview(day: TodayPreviewData.today, earlierDays: [])
                EmptyDayPreview(day: yesterday, earlierDays: [TodayPreviewData.day(twoDaysAgo)])
            }
            .padding()
        }
        .background(Color.background)
    }
#endif

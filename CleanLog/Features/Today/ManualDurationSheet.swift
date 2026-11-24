import SwiftUI

struct ManualDurationSheet: View {
    private enum Layout {
        static let spacing: CGFloat = 16
    }

    private enum Limits {
        static let hours = 0...23
        static let minutes = 0...59
    }

    let viewModel: DayViewModel

    @State private var parts: DurationParts
    @Environment(\.dismiss) private var dismiss

    init(viewModel: DayViewModel) {
        self.viewModel = viewModel
        _parts = State(initialValue: viewModel.manualDurationParts)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Layout.spacing) {
                HStack(spacing: 0) {
                    DurationWheel(
                        label: .todayDurationHours,
                        unit: .todayDurationHoursUnit,
                        range: Limits.hours,
                        value: $parts.hours
                    )
                    DurationWheel(
                        label: .todayDurationMinutes,
                        unit: .todayDurationMinutesUnit,
                        range: Limits.minutes,
                        value: $parts.minutes
                    )
                }
                if viewModel.canResetManualDuration {
                    Button(action: reset) {
                        Text(.todayDurationReset)
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle(Text(.todayDurationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: cancel) {
                        Text(.todayDurationCancel)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Text(.todayDurationSave)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func cancel() {
        dismiss()
    }

    private func save() {
        let parts = parts
        dismiss()
        Task { await viewModel.setManualDuration(parts) }
    }

    private func reset() {
        dismiss()
        Task { await viewModel.resetManualDuration() }
    }
}

private struct DurationWheel: View {
    private enum Layout {
        static let unitSpacing: CGFloat = 4
    }

    let label: LocalizedStringResource
    let unit: LocalizedStringResource
    let range: ClosedRange<Int>
    @Binding var value: Int

    var body: some View {
        HStack(spacing: Layout.unitSpacing) {
            Picker(selection: $value) {
                ForEach(range, id: \.self) { number in
                    Text(number, format: .number)
                        .monospacedDigit()
                        .tag(number)
                }
            } label: {
                Text(label)
            }
            .pickerStyle(.wheel)
            Text(unit)
                .font(.body)
                .foregroundStyle(Color.inkSecondary)
                .accessibilityHidden(true)
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var viewModel = DayViewModel(
            day: TodayPreviewData.today.adding(days: -1, calendar: .current),
            today: TodayPreviewData.today,
            workDays: FakeWorkDayRepository(),
            apartments: FakeApartmentRepository()
        )
        Color.background
            .sheet(isPresented: .constant(true)) {
                ManualDurationSheet(viewModel: viewModel)
            }
    }
#endif

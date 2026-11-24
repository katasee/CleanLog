import SwiftUI

private enum TileLayout {
    static let minHeight: CGFloat = 74
    static let minWidth: CGFloat = 96
    static let cornerRadius: CGFloat = 22
    static let textSpacing: CGFloat = 2
    static let newTileDash: [CGFloat] = [6, 4]
    static let newTileLineWidth: CGFloat = 1.5
    static let newTileBorderOpacity: Double = 0.5
}

struct DayPlanView: View {
    private enum Layout {
        static let margin: CGFloat = 18
        static let backdrop = [
            BackdropCircle(
                tone: .glow,
                origin: CGPoint(x: 170, y: -90),
                diameter: 340,
                opacity: 0.55
            ),
            BackdropCircle(
                tone: .mist,
                origin: CGPoint(x: -140, y: 360),
                diameter: 300,
                opacity: 0.6
            ),
        ]
    }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DayPlanViewModel

    init(day: DayKey, today: DayKey, dependencies: AppDependencies) {
        self.init(
            viewModel: DayPlanViewModel(
                day: day,
                today: today,
                apartments: dependencies.apartments,
                workDays: dependencies.workDays
            )
        )
    }

    init(viewModel: DayPlanViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                DayPlanGrid(viewModel: viewModel)
                    .padding(Layout.margin)
            }
            .screenBackground(Layout.backdrop)
            .safeAreaInset(edge: .bottom) {
                ConfirmButton(
                    title: viewModel.confirmTitle,
                    isEnabled: viewModel.canConfirm,
                    action: requestConfirm
                )
                .padding(Layout.margin)
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(.dayPlanSearchPrompt)
            )
            .navigationTitle(Text(verbatim: viewModel.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: close) {
                        Label {
                            Text(.dayPlanActionClose)
                        } icon: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: requestConfirm) {
                        Label {
                            Text(verbatim: viewModel.confirmTitle)
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    }
                    .disabled(!viewModel.canConfirm)
                }
            }
        }
        .fullScreenCover(item: $viewModel.newApartmentForm, content: ApartmentFormView.init)
        .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}
        .task {
            await viewModel.observe()
        }
    }

    private func close() {
        dismiss()
    }

    private func requestConfirm() {
        Task { await confirm() }
    }

    private func confirm() async {
        if await viewModel.confirm() {
            dismiss()
        }
    }
}

private struct DayPlanGrid: View {
    private enum Layout {
        static let spacing: CGFloat = 16
        static let gridSpacing: CGFloat = 10
        static let headerPadding: CGFloat = 4
    }

    let viewModel: DayPlanViewModel

    @ScaledMetric(relativeTo: .title3) private var tileMinWidth = TileLayout.minWidth

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            DayPlanHeader(selectedCountText: viewModel.selectedCountText)
                .padding(.horizontal, Layout.headerPadding)
            if let emptyMessage = viewModel.emptyMessage {
                Text(verbatim: emptyMessage)
                    .font(.body)
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.horizontal, Layout.headerPadding)
            }
            LazyVGrid(columns: columns, spacing: Layout.gridSpacing) {
                ForEach(viewModel.tiles) { tile in
                    DayPlanTileButton(tile: tile, onToggle: toggleSelection)
                }
                NewApartmentTile(action: viewModel.startNewApartment)
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: tileMinWidth), spacing: Layout.gridSpacing)]
    }

    private func toggleSelection(of id: Apartment.ID) {
        viewModel.toggleSelection(of: id)
    }
}

private struct DayPlanHeader: View {
    let selectedCountText: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                DayPlanSectionTitle()
                Spacer(minLength: 0)
                SelectedCount(text: selectedCountText)
            }
            VStack(alignment: .leading) {
                DayPlanSectionTitle()
                SelectedCount(text: selectedCountText)
            }
        }
    }
}

private struct DayPlanSectionTitle: View {
    var body: some View {
        Text(.dayPlanSectionTitle)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.inkSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct SelectedCount: View {
    let text: String?

    var body: some View {
        if let text {
            Text(verbatim: text)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(Color.inkSecondary)
        }
    }
}

private struct DayPlanTileButton: View {
    let tile: DayPlanTile
    let onToggle: (Apartment.ID) -> Void

    @ScaledMetric(relativeTo: .title3) private var minHeight = TileLayout.minHeight

    var body: some View {
        Button(action: toggle) {
            VStack(spacing: TileLayout.textSpacing) {
                Text(verbatim: tile.name)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Text(verbatim: tile.priceText)
                    .font(.footnote.weight(.medium))
                    .monospacedDigit()
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(tile.isSelected ? Color.onAccent : Color.ink)
            .padding(TileLayout.textSpacing)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(
                tile.isSelected ? Color.accent : Color.card,
                in: .rect(cornerRadius: TileLayout.cornerRadius)
            )
            .contentShape(.rect(cornerRadius: TileLayout.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(tile.isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: tile.isSelected)
    }

    private func toggle() {
        onToggle(tile.id)
    }
}

private struct NewApartmentTile: View {
    let action: () -> Void

    @ScaledMetric(relativeTo: .title3) private var minHeight = TileLayout.minHeight

    var body: some View {
        Button(action: action) {
            VStack(spacing: TileLayout.textSpacing) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                Text(.dayPlanActionNew)
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color.accent)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .overlay {
                RoundedRectangle(cornerRadius: TileLayout.cornerRadius)
                    .strokeBorder(
                        Color.accent.opacity(TileLayout.newTileBorderOpacity),
                        style: StrokeStyle(lineWidth: TileLayout.newTileLineWidth, dash: TileLayout.newTileDash)
                    )
            }
            .contentShape(.rect(cornerRadius: TileLayout.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct ConfirmButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.headline)
                .monospacedDigit()
                .frame(maxWidth: .infinity)
        }
        .prominentActionStyle()
        .disabled(!isEnabled)
    }
}

#if DEBUG
    #Preview("Some planned") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                DayPlanView(
                    day: DayPlanPreviewData.today,
                    today: DayPlanPreviewData.today,
                    dependencies: DayPlanPreviewData.dependencies(plannedCount: 2)
                )
            }
    }

    #Preview("Empty template") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                DayPlanView(
                    day: DayPlanPreviewData.today.adding(days: 1, calendar: .current),
                    today: DayPlanPreviewData.today,
                    dependencies: AppDependencies.preview()
                )
            }
    }

    #Preview("No match") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                DayPlanView(viewModel: DayPlanPreviewData.viewModel(searchText: "999"))
            }
    }
#endif

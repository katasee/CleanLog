import SwiftUI

struct ApartmentsView: View {
    private enum Layout {
        static let backdrop = [
            BackdropCircle(
                tone: .mist,
                origin: CGPoint(x: 180, y: -60),
                diameter: 340,
                opacity: 0.6
            ),
            BackdropCircle(
                tone: .glow,
                origin: CGPoint(x: -150, y: 460),
                diameter: 300,
                opacity: 0.4
            ),
        ]
        static let pinnedButtonBottomPadding: CGFloat = 8
    }

    @State private var viewModel: ApartmentsViewModel
    @State private var isShowingSettings = false

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: ApartmentsViewModel(repository: dependencies.apartments))
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.showsEmptyState {
                    ApartmentsEmptyState(add: add)
                } else {
                    ApartmentList(viewModel: viewModel)
                        .safeAreaInset(edge: .bottom) {
                            AddApartmentButton(action: add)
                                .padding(.bottom, Layout.pinnedButtonBottomPadding)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenBackground(Layout.backdrop)
            .navigationTitle(Text(.tabApartmentsTitle))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: openSettings) {
                        Label {
                            Text(.apartmentsActionSettings)
                        } icon: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
            .modifier(DeletionConfirmation(viewModel: viewModel))
            .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}
            .fullScreenCover(item: $viewModel.sheet) { sheet in
                ApartmentFormView(viewModel: viewModel.makeFormViewModel(for: sheet))
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(dependencies: dependencies)
            }
        }
        .task {
            await viewModel.observe()
        }
    }

    private func openSettings() {
        isShowingSettings = true
    }

    private func add() {
        withTransaction(\.disablesAnimations, true) {
            viewModel.add()
        }
    }
}

private struct ApartmentList: View {
    let viewModel: ApartmentsViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.rows) { row in
                    Button {
                        edit(row.id)
                    } label: {
                        ApartmentRowView(row: row)
                    }
                    .listRowBackground(Color.card)
                    .swipeActions {
                        Button {
                            viewModel.requestDeletion(row.id)
                        } label: {
                            Label {
                                Text(.apartmentsDeleteAction)
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                        .tint(Color.destructive)
                    }
                }
            } header: {
                Text(.apartmentsCount(viewModel.count))
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .textCase(nil)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func edit(_ id: UUID) {
        withTransaction(\.disablesAnimations, true) {
            viewModel.edit(id)
        }
    }
}

private struct ApartmentsEmptyState: View {
    private enum Layout {
        static let iconToTitle: CGFloat = 16
        static let titleToButton: CGFloat = 32
        static let titlePadding: CGFloat = 32
        static let iconCircleDiameter: CGFloat = 88
    }

    let add: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var iconCircleDiameter = Layout.iconCircleDiameter

    var body: some View {
        VStack(spacing: Layout.titleToButton) {
            VStack(spacing: Layout.iconToTitle) {
                Image(systemName: "building.2")
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: iconCircleDiameter, height: iconCircleDiameter)
                    .background(Color.accentSoft, in: .circle)
                    .accessibilityHidden(true)
                Text(.apartmentsEmptyTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Layout.titlePadding)
            }
            AddApartmentButton(action: add)
        }
    }
}

private struct AddApartmentButton: View {
    private enum Layout {
        static let horizontalPadding: CGFloat = 16
    }

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(.apartmentsActionAdd)
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
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

private struct DeletionConfirmation: ViewModifier {
    @Bindable var viewModel: ApartmentsViewModel

    func body(content: Content) -> some View {
        content.alert(
            Text(.apartmentsDeleteTitle(viewModel.pendingDeletion?.name ?? "")),
            isPresented: $viewModel.isConfirmingDeletion,
            presenting: viewModel.pendingDeletion
        ) { row in
            Button(role: .destructive) {
                Task { await viewModel.confirmDeletion(of: row) }
            } label: {
                Text(.apartmentsDeleteAction)
            }
            Button(role: .cancel, action: viewModel.cancelDeletion) {
                Text(.commonActionCancel)
            }
        } message: { _ in
            Text(.apartmentsDeleteMessage)
        }
    }
}

#if DEBUG
    #Preview("Template") {
        ApartmentsView(
            dependencies: AppDependencies.preview(apartments: FakeApartmentRepository(ApartmentsPreviewData.template))
        )
    }

    #Preview("Empty") {
        ApartmentsView(dependencies: AppDependencies.preview())
    }
#endif

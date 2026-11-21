import SwiftUI

struct ApartmentsView: View {
    @State private var viewModel: ApartmentsViewModel

    init(repository: any ApartmentRepository) {
        _viewModel = State(initialValue: ApartmentsViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.showsEmptyState {
                    ApartmentsEmptyState(viewModel: viewModel)
                } else {
                    ApartmentList(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
            .navigationTitle(Text(.tabApartmentsTitle))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.add()
                    } label: {
                        Label {
                            Text(.apartmentsActionAdd)
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .modifier(DeletionConfirmation(viewModel: viewModel))
            .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}
            .sheet(item: $viewModel.sheet) { _ in
                Color.background
            }
        }
        .task {
            await viewModel.observe()
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
                        viewModel.edit(row.id)
                    } label: {
                        ApartmentRowView(row: row)
                    }
                    .listRowBackground(Color.card)
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.requestDeletion(row.id)
                        } label: {
                            Label {
                                Text(.apartmentsDeleteAction)
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text(.apartmentsCount(viewModel.count))
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .textCase(nil)
            } footer: {
                Text(.apartmentsFootnote)
                    .font(.footnote)
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

private struct ApartmentsEmptyState: View {
    let viewModel: ApartmentsViewModel

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.apartmentsEmptyTitle)
                    .foregroundStyle(Color.ink)
            } icon: {
                Image(systemName: "building.2")
                    .foregroundStyle(Color.inkSecondary)
            }
        } actions: {
            Button {
                viewModel.add()
            } label: {
                Text(.apartmentsEmptyAction)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct DeletionConfirmation: ViewModifier {
    @Bindable var viewModel: ApartmentsViewModel

    func body(content: Content) -> some View {
        content.alert(
            Text(.apartmentsDeleteTitle(viewModel.pendingDeletion?.name ?? "")),
            isPresented: $viewModel.isConfirmingDeletion,
            presenting: viewModel.pendingDeletion
        ) { _ in
            Button(role: .destructive) {
                Task { await viewModel.confirmDeletion() }
            } label: {
                Text(.apartmentsDeleteAction)
            }
            Button(role: .cancel) {
                viewModel.cancelDeletion()
            } label: {
                Text(.commonActionCancel)
            }
        } message: { _ in
            Text(.apartmentsDeleteMessage)
        }
    }
}

#if DEBUG
    #Preview("Template") {
        ApartmentsView(repository: FakeApartmentRepository(ApartmentsPreviewData.template))
    }

    #Preview("Empty") {
        ApartmentsView(repository: FakeApartmentRepository())
    }
#endif

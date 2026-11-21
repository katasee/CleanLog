import SwiftUI

private struct NameField: View {
    @Bindable var viewModel: ApartmentFormViewModel

    var body: some View {
        LabeledContent {
            TextField(text: $viewModel.name) {
                Text(.apartmentsFormFieldName)
            }
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
        } label: {
            Text(.apartmentsFormFieldName)
        }
        if let nameError = viewModel.nameError {
            Text(nameError)
                .font(.footnote)
                .foregroundStyle(Color.warning)
        }
    }
}

private struct PriceField: View {
    @Binding var priceText: String

    var body: some View {
        LabeledContent {
            HStack {
                TextField(text: $priceText) {
                    Text(.apartmentsFormFieldPrice)
                }
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                Text(verbatim: MoneyFormat.currencySymbol)
                    .foregroundStyle(Color.inkSecondary)
            }
        } label: {
            Text(.apartmentsFormFieldPrice)
        }
    }
}

struct ApartmentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ApartmentFormViewModel

    init(viewModel: ApartmentFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NameField(viewModel: viewModel)
                    PriceField(priceText: $viewModel.priceText)
                    LabeledContent {
                        TextField(text: $viewModel.accessCode, prompt: Text(.apartmentsFormPlaceholderOptional)) {
                            Text(.apartmentsFormFieldAccessCode)
                        }
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                    } label: {
                        Text(.apartmentsFormFieldAccessCode)
                    }
                    Toggle(isOn: $viewModel.isReportedSeparately) {
                        Text(.apartmentsFormFieldSeparate)
                    }
                    .tint(Color.accent)
                }
                .listRowBackground(Color.card)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(.commonActionCancel)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    } label: {
                        Text(.commonActionSave)
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}
        }
        .presentationDetents([.medium, .large])
    }
}

#if DEBUG
    #Preview("New") {
        ApartmentFormView(
            viewModel: ApartmentFormViewModel(repository: FakeApartmentRepository(), editing: nil)
        )
    }

    #Preview("Edit") {
        ApartmentFormView(
            viewModel: ApartmentFormViewModel(
                repository: FakeApartmentRepository(ApartmentsPreviewData.template),
                editing: ApartmentsPreviewData.template.last
            )
        )
    }
#endif

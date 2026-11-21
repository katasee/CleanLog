import SwiftUI

private enum FormLayout {
    static let rowMinHeight: CGFloat = 44
    static let buttonSpacing: CGFloat = 12
    static let buttonsTopPadding: CGFloat = 16
    static let stackedRowSpacing: CGFloat = 4
}

private struct FormRowStyle: LabeledContentStyle {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func makeBody(configuration: Configuration) -> some View {
        rowLayout {
            configuration.label
            configuration.content
        }
        .frame(minHeight: FormLayout.rowMinHeight)
    }

    private var rowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: FormLayout.stackedRowSpacing))
            : AnyLayout(HStackLayout())
    }
}

private struct NameField: View {
    @Bindable var viewModel: ApartmentFormViewModel
    let isFocused: FocusState<Bool>.Binding

    var body: some View {
        LabeledContent {
            TextField(text: $viewModel.name) {
                Text(.apartmentsFormFieldName)
            }
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
            .focused(isFocused)
        } label: {
            Text(.apartmentsFormFieldName)
        }
        if let nameError = viewModel.nameError {
            Text(nameError)
                .font(.footnote)
                .foregroundStyle(Color.warning)
                .frame(maxWidth: .infinity, alignment: .leading)
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

private struct AccessCodeField: View {
    @Binding var accessCode: String

    var body: some View {
        LabeledContent {
            TextField(text: $accessCode, prompt: Text(.apartmentsFormPlaceholderOptional)) {
                Text(.apartmentsFormFieldAccessCode)
            }
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
        } label: {
            Text(.apartmentsFormFieldAccessCode)
        }
    }
}

private struct SaveButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(.commonActionSave)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(!isEnabled)
    }
}

private struct CancelButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(.commonActionCancel)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }
}

private struct FormButtons: View {
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: FormLayout.buttonSpacing) {
                CancelButton(action: onCancel)
                SaveButton(isEnabled: canSave, action: onSave)
            }
            VStack(spacing: FormLayout.buttonSpacing) {
                SaveButton(isEnabled: canSave, action: onSave)
                CancelButton(action: onCancel)
            }
        }
        .padding(.top, FormLayout.buttonsTopPadding)
    }
}

private struct FormCard: View {
    @Bindable var viewModel: ApartmentFormViewModel
    let isNameFocused: FocusState<Bool>.Binding
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    NameField(viewModel: viewModel, isFocused: isNameFocused)
                    Divider().overlay(Color.hairline)
                    PriceField(priceText: $viewModel.priceText)
                    Divider().overlay(Color.hairline)
                    AccessCodeField(accessCode: $viewModel.accessCode)
                }
                .labeledContentStyle(FormRowStyle())
                Divider().overlay(Color.hairline)
                Toggle(isOn: $viewModel.isReportedSeparately) {
                    Text(.apartmentsFormFieldSeparate)
                }
                .tint(Color.accent)
                .frame(minHeight: FormLayout.rowMinHeight)
            }
            .foregroundStyle(Color.ink)
            FormButtons(canSave: viewModel.canSave, onCancel: onCancel, onSave: onSave)
        }
        .cardSurface()
    }
}

struct ApartmentFormView: View {
    private enum Layout {
        static let margin: CGFloat = 20
        static let maxCardWidth: CGFloat = 480
        static let hiddenScale: CGFloat = 0.94
    }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ApartmentFormViewModel
    @State private var isShown = false
    @FocusState private var isNameFocused: Bool

    init(viewModel: ApartmentFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(isShown ? 1 : 0)
            ScrollView {
                FormCard(
                    viewModel: viewModel,
                    isNameFocused: $isNameFocused,
                    onCancel: close,
                    onSave: requestSave
                )
                .frame(maxWidth: Layout.maxCardWidth)
                .padding(Layout.margin)
                .frame(maxWidth: .infinity)
                .opacity(isShown ? 1 : 0)
                .scaleEffect(isShown ? 1 : Layout.hiddenScale)
            }
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationBackground(.clear)
        .accessibilityAction(.escape, close)
        .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}
        .onAppear(perform: appear)
    }

    private func appear() {
        isNameFocused = viewModel.isAdding
        withAnimation(.snappy) {
            isShown = true
        }
    }

    private func close() {
        withAnimation(.snappy) {
            isShown = false
        } completion: {
            withTransaction(\.disablesAnimations, true) {
                dismiss()
            }
        }
    }

    private func requestSave() {
        Task { await save() }
    }

    private func save() async {
        if await viewModel.save() {
            close()
        }
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

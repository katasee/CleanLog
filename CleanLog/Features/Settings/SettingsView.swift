import SwiftUI

struct SettingsView: View {
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
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: SettingsViewModel

    init(dependencies: AppDependencies) {
        self.init(
            viewModel: SettingsViewModel(
                settings: dependencies.settings,
                permission: dependencies.notificationPermission,
                version: dependencies.appVersion
            )
        )
    }

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                SettingsReminderSection(viewModel: viewModel)
                if viewModel.isPermissionDenied {
                    SettingsPermissionSection(settingsURL: viewModel.notificationSettingsURL)
                }
                SettingsVersionFooter(versionText: viewModel.versionText)
            }
            .scrollContentBackground(.hidden)
            .screenBackground(Layout.backdrop)
            .navigationTitle(Text(.settingsTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: close) {
                        Label {
                            Text(.settingsActionClose)
                        } icon: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
            .alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}
        }
        .task {
            await viewModel.observe()
        }
        .task(id: scenePhase) {
            if scenePhase == .active {
                await viewModel.refreshPermission()
            }
        }
    }

    private func close() {
        dismiss()
    }
}

private struct SettingsReminderSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Section {
            Toggle(isOn: $viewModel.isReminderOn) {
                Text(.settingsReminderToggle)
                    .foregroundStyle(Color.ink)
            }
            .listRowBackground(Color.card)
            if viewModel.isReminderOn {
                DatePicker(selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute) {
                    Text(.settingsReminderTime)
                        .foregroundStyle(Color.ink)
                }
                .datePickerStyle(.compact)
                .listRowBackground(Color.card)
            }
        } header: {
            Text(.settingsReminderHeader)
                .foregroundStyle(Color.inkSecondary)
        } footer: {
            Text(.settingsReminderFooter)
                .foregroundStyle(Color.inkSecondary)
        }
        .onChange(of: viewModel.isReminderOn) {
            Task { await viewModel.reminderSwitchChanged() }
        }
        .onChange(of: viewModel.reminderTime) {
            Task { await viewModel.reminderTimeChanged() }
        }
    }
}

private struct SettingsPermissionSection: View {
    let settingsURL: URL

    var body: some View {
        Section {
            Text(.settingsPermissionDenied)
                .foregroundStyle(Color.ink)
                .listRowBackground(Color.card)
            Link(destination: settingsURL) {
                Text(.settingsPermissionOpen)
            }
            .listRowBackground(Color.card)
        }
    }
}

private struct SettingsVersionFooter: View {
    let versionText: String

    var body: some View {
        Section {
        } footer: {
            Text(verbatim: versionText)
                .font(.footnote)
                .foregroundStyle(Color.inkSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }
}

#if DEBUG
    #Preview("Off") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                SettingsView(viewModel: SettingsPreviewData.viewModel(SettingsPreviewData.off))
            }
    }

    #Preview("On") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                SettingsView(viewModel: SettingsPreviewData.viewModel(SettingsPreviewData.onAtSix))
            }
            .preferredColorScheme(.dark)
    }

    #Preview("Permission denied") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                SettingsView(
                    viewModel: SettingsPreviewData.viewModel(
                        SettingsPreviewData.onAtSix,
                        authorization: .denied
                    )
                )
            }
    }
#endif

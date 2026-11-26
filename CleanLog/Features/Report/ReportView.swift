import SwiftUI

struct ReportView: View {
    private enum Layout {
        static let margin: CGFloat = 18
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

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReportViewModel

    init(month: MonthKey, today: DayKey, dependencies: AppDependencies) {
        self.init(
            viewModel: ReportViewModel(
                month: month,
                today: today,
                workDays: dependencies.workDays,
                urlAvailability: dependencies.urlAvailability,
                pasteboard: dependencies.pasteboard
            )
        )
    }

    init(viewModel: ReportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Layout.spacing) {
                if viewModel.hasReport {
                    ReportTextCard(text: viewModel.text)
                } else {
                    ReportEmptyCard()
                }
                ReportActions(viewModel: viewModel)
            }
            .padding(Layout.margin)
            .screenBackground(Layout.backdrop)
            .navigationTitle(Text(verbatim: viewModel.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ReportTitle(title: viewModel.title, subtitle: viewModel.subtitle)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: close) {
                        Label {
                            Text(.reportActionClose)
                        } icon: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.observe()
        }
        .task(id: viewModel.copyCount) {
            await viewModel.holdConfirmation()
        }
    }

    private func close() {
        dismiss()
    }
}

private struct ReportTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack {
            Text(verbatim: title)
                .font(.headline)
                .foregroundStyle(Color.ink)
            Text(verbatim: subtitle)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Color.inkSecondary)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct ReportTextCard: View {
    let text: String

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(verbatim: text)
                .font(.body.monospaced())
                .foregroundStyle(Color.ink)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.reportTextLabel))
        .accessibilityValue(Text(verbatim: text))
    }
}

private struct ReportEmptyCard: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.reportEmpty)
            } icon: {
                Image(systemName: "doc.text")
            }
        }
        .foregroundStyle(Color.inkSecondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardSurface()
    }
}

private struct ReportActions: View {
    private enum Layout {
        static let spacing: CGFloat = 10
        static let copyDiameter: CGFloat = 58
    }

    let viewModel: ReportViewModel

    var body: some View {
        HStack(spacing: Layout.spacing) {
            ReportSendButton(action: viewModel.sendAction)
            GlassIconButton(
                systemImage: viewModel.isCopied ? "checkmark" : "doc.on.doc",
                label: viewModel.isCopied ? .reportActionCopied : .reportActionCopy,
                diameter: Layout.copyDiameter,
                action: viewModel.copy
            )
            .sensoryFeedback(.success, trigger: viewModel.copyCount)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .disabled(!viewModel.hasReport)
    }
}

private struct ReportSendButton: View {
    let action: ReportSendAction

    @Environment(\.openURL) private var openURL

    var body: some View {
        switch action {
        case .whatsApp(let url):
            Button {
                openURL(url)
            } label: {
                ReportActionLabel(title: .reportActionSend, systemImage: "paperplane")
            }
            .prominentActionStyle()
        case .share(let text):
            ShareLink(item: text) {
                ReportActionLabel(title: .reportActionShare, systemImage: "square.and.arrow.up")
            }
            .prominentActionStyle()
        }
    }
}

private struct ReportActionLabel: View {
    private enum Layout {
        static let minimumScale: CGFloat = 0.5
    }

    let title: LocalizedStringResource
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.headline)
        .lineLimit(1)
        .minimumScaleFactor(Layout.minimumScale)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
    #Preview("WhatsApp") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                ReportView(viewModel: ReportPreviewData.viewModel(isWhatsAppInstalled: true))
            }
    }

    #Preview("No WhatsApp") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                ReportView(viewModel: ReportPreviewData.viewModel(isWhatsAppInstalled: false))
            }
            .preferredColorScheme(.dark)
    }

    #Preview("Empty") {
        Color.background
            .sheet(isPresented: .constant(true)) {
                ReportView(viewModel: ReportPreviewData.emptyViewModel())
            }
    }
#endif

import SwiftUI

struct StepButton: View {
    private enum Layout {
        static let target: CGFloat = 44
    }

    let systemImage: String
    let label: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.inkSecondary)
                .frame(minWidth: Layout.target, minHeight: Layout.target)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

#Preview {
    StepButton(
        systemImage: "chevron.left",
        label: .todayHeaderPrevious,
        action: {}
    )
    .background(Color.background)
}

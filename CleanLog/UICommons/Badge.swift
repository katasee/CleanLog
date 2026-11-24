import SwiftUI

struct Badge: View {
    private enum Layout {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 3
    }

    let title: LocalizedStringResource

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accent)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)
            .background(Color.accentSoft, in: .capsule)
    }
}

#Preview {
    Badge(title: .todayBadgeSeparate)
        .padding()
        .background(Color.card)
}

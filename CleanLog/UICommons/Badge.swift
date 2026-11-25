import SwiftUI

struct Badge: View {
    private enum Layout {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 3
    }

    private let text: Text

    init(title: LocalizedStringResource) {
        text = Text(title)
    }

    init(text: String) {
        self.text = Text(verbatim: text)
    }

    var body: some View {
        text
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accent)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)
            .background(Color.accentSoft, in: .capsule)
    }
}

#Preview {
    VStack {
        Badge(title: .todayBadgeSeparate)
        Badge(text: "↑ 9% до жовтня")
    }
    .padding()
    .background(Color.card)
}

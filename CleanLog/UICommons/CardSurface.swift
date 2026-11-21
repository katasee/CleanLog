import SwiftUI

private struct CardSurface: ViewModifier {
    private enum Layout {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
    }

    func body(content: Content) -> some View {
        content
            .padding(Layout.padding)
            .background(Color.card, in: .rect(cornerRadius: Layout.cornerRadius))
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        Text(verbatim: "Листопад")
            .font(.subheadline)
            .foregroundStyle(Color.inkSecondary)
        Text(verbatim: "1 876 zł")
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.ink)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .cardSurface()
    .padding()
    .frame(maxHeight: .infinity)
    .background(Color.background)
}

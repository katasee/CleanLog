import SwiftUI

struct GlassIconButton: View {
    private enum Layout {
        static let target: CGFloat = 44
    }

    let systemImage: String
    let label: LocalizedStringResource
    let action: () -> Void

    @ScaledMetric(relativeTo: .title3) private var diameter = Layout.target

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.ink)
                .frame(width: diameter, height: diameter)
                .glassSurface(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

#Preview {
    GlassIconButton(
        systemImage: "xmark",
        label: .calendarActionClose,
        action: {}
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background)
}

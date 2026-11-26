import SwiftUI

struct GlassIconButton: View {
    private enum Layout {
        static let target: CGFloat = 44
    }

    private let systemImage: String
    private let label: LocalizedStringResource
    private let action: () -> Void

    @ScaledMetric private var diameter: CGFloat

    init(
        systemImage: String,
        label: LocalizedStringResource,
        diameter: CGFloat = Layout.target,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.action = action
        _diameter = ScaledMetric(wrappedValue: max(diameter, Layout.target), relativeTo: .title3)
    }

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

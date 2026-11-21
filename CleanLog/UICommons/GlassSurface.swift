import SwiftUI

private struct GlassSurface<SurfaceShape: Shape>: ViewModifier {
    let shape: SurfaceShape

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}

extension View {
    func glassSurface(_ shape: some Shape) -> some View {
        modifier(GlassSurface(shape: shape))
    }
}

#Preview {
    Button {
    } label: {
        Image(systemName: "calendar")
            .font(.title3)
            .foregroundStyle(Color.ink)
            .frame(width: 44, height: 44)
            .glassSurface(.circle)
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background)
}

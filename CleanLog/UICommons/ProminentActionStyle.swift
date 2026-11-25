import SwiftUI

private struct ProminentActionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

extension View {
    func prominentActionStyle() -> some View {
        modifier(ProminentActionStyle())
    }
}

#Preview {
    Button {
    } label: {
        Text(.calendarActionOpen)
            .font(.headline)
            .frame(maxWidth: .infinity)
    }
    .prominentActionStyle()
    .padding()
    .background(Color.background)
}

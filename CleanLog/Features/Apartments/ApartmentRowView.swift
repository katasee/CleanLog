import SwiftUI

struct ApartmentRowView: View {
    private enum Layout {
        static let spacing: CGFloat = 12
        static let titleSpacing: CGFloat = 8
        static let minHeight: CGFloat = 44
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let row: ApartmentRow

    var body: some View {
        HStack(spacing: Layout.spacing) {
            titleLayout {
                Text(verbatim: row.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ink)
                if row.isReportedSeparately {
                    Badge(title: .apartmentsBadgeSeparate)
                }
            }
            Spacer(minLength: 0)
            Text(verbatim: row.priceText)
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(Color.inkSecondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.inkSecondary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: Layout.minHeight)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private var titleLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Layout.titleSpacing))
            : AnyLayout(HStackLayout(spacing: Layout.titleSpacing))
    }
}

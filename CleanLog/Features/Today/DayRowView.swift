import SwiftUI

struct DayRowView: View {
    private enum Layout {
        static let spacing: CGFloat = 14
        static let titleSpacing: CGFloat = 8
        static let codeSpacing: CGFloat = 6
        static let minHeight: CGFloat = 50
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let row: DayRow

    var body: some View {
        HStack(spacing: Layout.spacing) {
            CheckCircle(isChecked: row.isCleaned)
            titleLayout {
                Text(verbatim: row.name)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.ink)
                if row.isReportedSeparately {
                    Badge(title: .todayBadgeSeparate)
                }
            }
            Spacer(minLength: 0)
            if let accessCode = row.accessCode {
                HStack(spacing: Layout.codeSpacing) {
                    Image(systemName: "key")
                        .accessibilityLabel(Text(.todayRowAccessCode))
                    Text(verbatim: accessCode)
                        .monospacedDigit()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(row.isCleaned ? Color.ink : Color.inkSecondary)
            }
        }
        .frame(minHeight: Layout.minHeight)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(row.isCleaned ? .isSelected : [])
    }

    private var titleLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Layout.titleSpacing))
            : AnyLayout(HStackLayout(spacing: Layout.titleSpacing))
    }
}

private struct CheckCircle: View {
    let isChecked: Bool

    var body: some View {
        Group {
            if isChecked {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.onAccent, Color.accent)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .font(.title2)
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview {
        List {
            DayRowView(
                row: DayRow(
                    id: UUID(),
                    name: "100",
                    accessCode: "4821",
                    isReportedSeparately: false,
                    isCleaned: true
                )
            )
            DayRowView(
                row: DayRow(
                    id: UUID(),
                    name: "106",
                    accessCode: "7409",
                    isReportedSeparately: true,
                    isCleaned: false
                )
            )
            DayRowView(
                row: DayRow(
                    id: UUID(),
                    name: "102",
                    accessCode: nil,
                    isReportedSeparately: false,
                    isCleaned: false
                )
            )
        }
    }
#endif

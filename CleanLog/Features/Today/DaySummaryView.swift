import SwiftUI

struct DaySummaryView: View {
    let summary: DaySummary

    var body: some View {
        switch summary {
        case .today(let today):
            TodaySummaryCards(summary: today)
        case .past(let earned):
            SingleSummaryCard(title: .todaySummaryPastEarned, amount: earned)
        case .future(let planned):
            SingleSummaryCard(title: .todaySummaryFuturePlanned, amount: planned)
        }
    }
}

private enum SummaryLayout {
    static let cardSpacing: CGFloat = 12
    static let contentSpacing: CGFloat = 8
    static let amountSpacing: CGFloat = 4
}

private struct TodaySummaryCards: View {
    let summary: TodaySummary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        cardsLayout {
            SummaryCard {
                SummaryCaption(text: Text(.todaySummaryToday))
                AmountLine(amount: summary.earned, detail: summary.planned)
                ProgressBar(progress: summary.progress)
            }
            SummaryCard {
                SummaryCaption(text: Text(verbatim: summary.month))
                AmountLine(amount: summary.monthEarned, detail: nil)
                SummaryCaption(text: Text(verbatim: summary.monthCount))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var cardsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: SummaryLayout.cardSpacing))
            : AnyLayout(HStackLayout(alignment: .top, spacing: SummaryLayout.cardSpacing))
    }
}

private struct SummaryCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SummaryLayout.contentSpacing) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

private struct SingleSummaryCard: View {
    let title: LocalizedStringResource
    let amount: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                SummaryTitle(title: title)
                Spacer(minLength: SummaryLayout.cardSpacing)
                AmountText(amount: amount)
            }
            VStack(alignment: .leading, spacing: SummaryLayout.contentSpacing) {
                SummaryTitle(title: title)
                AmountText(amount: amount)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

private struct SummaryTitle: View {
    let title: LocalizedStringResource

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.inkSecondary)
    }
}

private struct SummaryCaption: View {
    let text: Text

    var body: some View {
        text
            .font(.footnote.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(Color.inkSecondary)
    }
}

private struct AmountLine: View {
    let amount: String
    let detail: String?

    var body: some View {
        if let detail {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: SummaryLayout.amountSpacing) {
                    AmountText(amount: amount)
                    SummaryCaption(text: Text(verbatim: detail))
                }
                VStack(alignment: .leading) {
                    AmountText(amount: amount)
                    SummaryCaption(text: Text(verbatim: detail))
                }
            }
        } else {
            AmountText(amount: amount)
        }
    }
}

private struct AmountText: View {
    let amount: String

    var body: some View {
        Text(verbatim: amount)
            .font(.title2.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(Color.ink)
    }
}

private struct ProgressBar: View {
    private enum Layout {
        static let height: CGFloat = 6
    }

    let progress: Double

    var body: some View {
        Capsule()
            .fill(Color.accentSoft)
            .frame(height: Layout.height)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.accent)
                    .scaleEffect(x: progress, anchor: .leading)
            }
            .clipShape(.capsule)
            .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview {
        VStack(spacing: 16) {
            DaySummaryView(
                summary: .today(
                    TodaySummary(
                        earned: "112 zł",
                        planned: "з 224 zł",
                        progress: 0.5,
                        month: "Листопад",
                        monthEarned: "1 988 zł",
                        monthCount: "63 квартири"
                    )
                )
            )
            DaySummaryView(summary: .past(earned: "140 zł"))
            DaySummaryView(summary: .future(planned: "196 zł"))
        }
        .padding()
        .background(Color.background)
    }
#endif

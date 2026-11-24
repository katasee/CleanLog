import SwiftUI

struct DayListView: View {
    private enum Layout {
        static let rowInsets = EdgeInsets(
            top: 4,
            leading: 18,
            bottom: 4,
            trailing: 18
        )
    }

    let viewModel: DayViewModel
    let onAddApartment: () -> Void

    var body: some View {
        Section {
            ForEach(viewModel.rows) { row in
                DayListRow(viewModel: viewModel, row: row)
                    .listRowInsets(Layout.rowInsets)
                    .listRowBackground(Color.card)
            }
            AddApartmentRow(action: onAddApartment)
                .listRowInsets(Layout.rowInsets)
                .listRowBackground(Color.card)
        } header: {
            DayListHeader(progress: viewModel.cleanedCountText)
        }
    }
}

private struct DayListRow: View {
    let viewModel: DayViewModel
    let row: DayRow

    var body: some View {
        Group {
            if viewModel.canTick {
                Button(action: tick) {
                    DayRowView(row: row)
                }
                .sensoryFeedback(.success, trigger: row.isCleaned) { _, isCleaned in isCleaned }
            } else {
                DayRowView(row: row)
            }
        }
        .swipeActions {
            Button(action: remove) {
                Label {
                    Text(.todayListRemove)
                } icon: {
                    Image(systemName: "minus.circle")
                }
            }
            .tint(Color.destructive)
        }
    }

    private func tick() {
        Task { await viewModel.setCleaned(row.id, to: !row.isCleaned) }
    }

    private func remove() {
        Task { await viewModel.remove(row.id) }
    }
}

private struct AddApartmentRow: View {
    private enum Layout {
        static let minHeight: CGFloat = 44
    }

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(.todayListAdd)
            } icon: {
                Image(systemName: "plus")
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.accent)
            .frame(maxWidth: .infinity, minHeight: Layout.minHeight, alignment: .leading)
            .contentShape(.rect)
        }
    }
}

private struct DayListHeader: View {
    let progress: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                DayListTitle()
                Spacer(minLength: 0)
                DayListProgress(text: progress)
            }
            VStack(alignment: .leading) {
                DayListTitle()
                DayListProgress(text: progress)
            }
        }
        .textCase(nil)
    }
}

private struct DayListTitle: View {
    var body: some View {
        Text(.todayListTitle)
            .font(.title3.weight(.bold))
            .foregroundStyle(Color.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct DayListProgress: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(Color.inkSecondary)
    }
}

import SwiftUI
import VertoCore

/// Past translations, newest first. Clicking one puts it back in the fields.
struct HistoryView: View {

    @ObservedObject private var store = HistoryStore.shared
    let onPick: (TranslationRecord) -> Void

    var body: some View {
        if store.history.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.tertiary)
                Text(L.historyEmpty)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.history.records) { record in
                        row(record)
                        Divider().opacity(0.4).padding(.leading, 14)
                    }
                }
            }
        }
    }

    private func row(_ record: TranslationRecord) -> some View {
        Button {
            onPick(record)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("\(record.source.badge) → \(record.target.badge)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(record.date, style: .time)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Text(record.sourceText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(record.targetText)
                    .font(.system(size: 13))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .contextMenu {
            Button(L.historyDelete) { store.remove(record.id) }
        }
    }
}

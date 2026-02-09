import SwiftUI

struct HistoryView: View {
    @Environment(HistoryStore.self) private var store
    @Environment(DictationManager.self) private var manager
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search transcriptions...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text("\(store.records.count) total")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(.bar)

            Divider()

            // Records list
            let filtered = store.search(query: searchText)
            if filtered.isEmpty {
                ContentUnavailableView {
                    Label(
                        searchText.isEmpty ? "No Dictations Yet" : "No Results",
                        systemImage: searchText.isEmpty ? "mic.slash" : "magnifyingglass"
                    )
                } description: {
                    Text(
                        searchText.isEmpty
                            ? "Start dictating and your history will appear here."
                            : "Try a different search term."
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filtered) { record in
                            HistoryRowView(record: record, manager: manager, store: store)
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Row View

struct HistoryRowView: View {
    let record: DictationRecord
    let manager: DictationManager
    let store: HistoryStore
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Full text — no line limit
            Text(record.text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Bottom bar: metadata + actions
            HStack(spacing: 12) {
                // Metadata
                Label(relativeTimestamp(record.timestamp), systemImage: "clock")
                Label("\(record.wordCount) words", systemImage: "text.word.spacing")
                Label(formattedDuration(record.duration), systemImage: "timer")

                Spacer()

                // Copy button
                Button {
                    manager.copyToClipboard(record.text)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(showCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")

                // Delete button
                Button {
                    store.deleteRecord(record)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func relativeTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(minutes)m \(secs)s"
    }
}

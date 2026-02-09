import SwiftUI

struct HistoryView: View {
    @Environment(HistoryStore.self) private var store
    @Environment(DictationManager.self) private var manager
    @State private var searchText = ""
    @State private var expandedRecordID: String?

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
                            ? "Your dictation history will appear here."
                            : "Try a different search term."
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filtered) { record in
                    HistoryRowView(
                        record: record,
                        isExpanded: expandedRecordID == record.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedRecordID == record.id {
                                expandedRecordID = nil
                            } else {
                                expandedRecordID = record.id
                            }
                        }
                    }
                    .contextMenu {
                        Button("Copy") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(record.text, forType: .string)
                        }
                        Button("Re-paste") {
                            Task {
                                manager.lastResult = record.text
                                await manager.rePasteLast()
                            }
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            store.deleteRecord(record)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .navigationTitle("History")
    }
}

// MARK: - Row View

struct HistoryRowView: View {
    let record: DictationRecord
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Text preview or full text
            Text(record.text)
                .font(.body)
                .lineLimit(isExpanded ? nil : 2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Metadata row
            HStack(spacing: 12) {
                Label(relativeTimestamp(record.timestamp), systemImage: "clock")
                Label("\(record.wordCount) words", systemImage: "text.word.spacing")
                Label(formattedDuration(record.duration), systemImage: "timer")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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

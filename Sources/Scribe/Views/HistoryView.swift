import SwiftUI

struct HistoryView: View {
    @Environment(HistoryStore.self) private var store
    @Environment(DictationManager.self) private var manager
    @State private var searchText = ""
    @State private var selectedRecordId: String?
    @State private var optimizationResult: DictationRecord?
    @State private var isOptimizing = false

    var body: some View {
        HSplitView {
            // Left: History list
            historyList
                .frame(minWidth: 300)

            // Right: Optimization panel (shown when a result exists)
            if let result = optimizationResult {
                optimizationPanel(result)
                    .frame(minWidth: 280, idealWidth: 320)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    // MARK: - History List

    private var historyList: some View {
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
                            HistoryRowView(
                                record: record,
                                manager: manager,
                                store: store,
                                isSelected: selectedRecordId == record.id,
                                isOptimizing: isOptimizing && selectedRecordId == record.id,
                                onOptimize: { mode in
                                    optimizeRecord(record, mode: mode)
                                }
                            )
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Optimization Panel

    private func optimizationPanel(_ record: DictationRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(.blue)
                Text("Optimization Result")
                    .font(.headline)
                Spacer()

                if let mode = record.optimizationMode {
                    Text(OptimizationMode(rawValue: mode)?.displayName ?? mode)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }

                Button {
                    manager.copyToClipboard(record.text)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy optimized text")

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        optimizationResult = nil
                        selectedRecordId = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close panel")
            }
            .padding()
            .background(.bar)

            Divider()

            // Optimized text
            ScrollView {
                Text(record.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            Divider()

            // Previous optimizations for this parent
            let parentId = record.parentId ?? record.id
            let history = store.optimizations(for: parentId).filter { $0.id != record.id }
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Previous Optimizations")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ForEach(history) { prev in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                optimizationResult = prev
                            }
                        } label: {
                            HStack {
                                if let mode = prev.optimizationMode {
                                    Text(OptimizationMode(rawValue: mode)?.displayName ?? mode)
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                                Text(prev.text.prefix(60) + (prev.text.count > 60 ? "..." : ""))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Actions

    private func optimizeRecord(_ record: DictationRecord, mode: OptimizationMode) {
        selectedRecordId = record.id
        isOptimizing = true
        Task {
            let result = await manager.optimizeText(record.text, mode: mode, parentId: record.id)
            isOptimizing = false
            if let result {
                withAnimation(.easeInOut(duration: 0.2)) {
                    optimizationResult = result
                }
            }
        }
    }
}

// MARK: - Row View

struct HistoryRowView: View {
    let record: DictationRecord
    let manager: DictationManager
    let store: HistoryStore
    let isSelected: Bool
    let isOptimizing: Bool
    let onOptimize: (OptimizationMode) -> Void
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

                // Optimize menu
                if manager.promptOptimizer.isConfigured {
                    if isOptimizing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Menu {
                            ForEach(OptimizationMode.allCases) { mode in
                                let isLocked = mode.requiresUnlock && !manager.promptOptimizer.optimizationUnlocked
                                Button {
                                    onOptimize(mode)
                                } label: {
                                    Label(mode.displayName, systemImage: isLocked ? "lock.fill" : mode.icon)
                                }
                                .disabled(isLocked)
                            }
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .help("Optimize with mode")
                    }
                }

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
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
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

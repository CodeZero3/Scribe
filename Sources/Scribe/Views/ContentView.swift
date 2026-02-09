import SwiftUI

struct ContentView: View {
    @Environment(DictationManager.self) private var manager
    @Environment(HistoryStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @State private var showCopied = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Scribe")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarItems
            }
        }
        .task {
            manager.onRequestReview = { [openWindow] in
                openWindow(id: "review")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            await manager.setup()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Dictation button
            dictationCard
                .padding()

            Divider()

            // Last transcription with copy button
            if !manager.lastResult.isEmpty {
                lastTranscriptionCard
                    .padding()
                Divider()
            }

            // Navigation
            List {
                NavigationLink(value: "history") {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink(value: "settings") {
                    Label("Settings", systemImage: "gear")
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 220)
    }

    // MARK: - Dictation Card

    private var dictationCard: some View {
        VStack(spacing: 12) {
            // Mic button
            Button {
                manager.toggleDictation()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: manager.isDictating ? "mic.fill" : "mic")
                        .font(.system(size: 36))
                        .foregroundStyle(manager.isDictating ? .red : .primary)
                        .symbolEffect(.pulse, isActive: manager.isDictating)

                    Text(manager.isDictating ? "Recording..." : "Start Dictation")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!manager.transcriptionEngine.isModelLoaded)

            // Status
            VStack(spacing: 4) {
                Text(manager.transcriptionEngine.loadingStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if !manager.statusMessage.isEmpty {
                    Text(manager.statusMessage)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            // Hotkey hint
            Text("Hold Ctrl+CapsLock")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
        }
    }

    // MARK: - Last Transcription Card

    private var lastTranscriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last Transcription")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    manager.copyToClipboard(manager.lastResult)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(showCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }

            Text(manager.lastResult)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Detail View

    private var detailView: some View {
        HistoryView()
            .environment(manager)
            .environment(store)
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarItems: some View {
        if !manager.lastResult.isEmpty {
            Button {
                manager.copyToClipboard(manager.lastResult)
            } label: {
                Label("Copy Last", systemImage: "doc.on.clipboard")
            }
            .help("Copy last dictation to clipboard")
        }

        if !manager.checkAccessibilityPermission() {
            Button {
                manager.requestAccessibilityPermission()
            } label: {
                Label("Grant Access", systemImage: "lock.shield")
            }
            .foregroundStyle(.red)
        }
    }
}

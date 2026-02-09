import SwiftUI

struct ContentView: View {
    @Environment(DictationManager.self) private var manager
    @Environment(HistoryStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @State private var showCopied = false
    @State private var isOptimizing = false
    @State private var selectedTab: SidebarTab = .history

    enum SidebarTab: String, CaseIterable {
        case history
        case optimize
        case settings
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle({
            switch selectedTab {
            case .history: "Scribe"
            case .optimize: "Optimize"
            case .settings: "Settings"
            }
        }())
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
            List(selection: $selectedTab) {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .tag(SidebarTab.history)
                Label("Settings", systemImage: "gear")
                    .tag(SidebarTab.settings)
                Label("Optimize", systemImage: "wand.and.stars")
                    .tag(SidebarTab.optimize)
            }
            .listStyle(.sidebar)

            // Mode toggles
            if manager.promptOptimizer.isConfigured {
                Divider()
                modeTogglesSection
            }
        }
        .frame(minWidth: 220)
    }

    // MARK: - Dictation Card

    private var dictationCard: some View {
        VStack(spacing: 12) {
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

            VStack(spacing: 4) {
                Text(manager.transcriptionEngine.loadingStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                if !manager.statusMessage.isEmpty {
                    Text(manager.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                }
            }
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.3), value: manager.statusMessage)

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
                if manager.promptOptimizer.isConfigured {
                    Button {
                        Task {
                            isOptimizing = true
                            let optimized = await manager.optimizeText(manager.lastResult)
                            manager.lastResult = optimized
                            isOptimizing = false
                        }
                    } label: {
                        if isOptimizing {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Optimize as AI prompt")
                    .disabled(isOptimizing)
                }

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

    // MARK: - Mode Toggles

    private var modeTogglesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Optimization")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)

            ForEach(OptimizationMode.allCases) { mode in
                modeToggleRow(mode)
            }
        }
        .padding(.vertical, 10)
    }

    private func modeToggleRow(_ mode: OptimizationMode) -> some View {
        let isLocked = mode.requiresUnlock && !manager.promptOptimizer.optimizationUnlocked
        return HStack(spacing: 8) {
            Image(systemName: mode.icon)
                .font(.caption)
                .foregroundColor(isLocked ? .secondary : .blue)
                .frame(width: 16)
            Text(mode.displayName)
                .font(.caption)
            Spacer()
            Toggle("", isOn: Binding(
                get: { manager.promptOptimizer.isModeEnabled(mode) },
                set: { _ in manager.promptOptimizer.toggleMode(mode) }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
            .disabled(isLocked)
        }
        .padding(.horizontal, 16)
        .opacity(isLocked ? 0.6 : 1.0)
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .history:
            HistoryView()
                .environment(manager)
                .environment(store)
        case .optimize:
            OptimizeView()
                .environment(manager)
        case .settings:
            SettingsView()
                .environment(manager)
        }
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

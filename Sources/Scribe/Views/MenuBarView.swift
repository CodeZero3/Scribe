import SwiftUI

struct MenuBarView: View {
    @Environment(DictationManager.self) private var manager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerSection
            Divider()
            accessibilitySection
            dictationSection
            transcribingSection
            repasteSection
            Divider()
            lastTranscriptionSection
            Divider()
            navigationSection
            Divider()
            quitSection
        }
        .padding(4)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Scribe")
                    .font(.headline)
                Spacer()
                Text("v0.1.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(manager.transcriptionEngine.loadingStatus)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !manager.statusMessage.isEmpty {
                Text(manager.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var accessibilitySection: some View {
        if !manager.checkAccessibilityPermission() {
            Button {
                manager.requestAccessibilityPermission()
            } label: {
                Label("Grant Accessibility Access", systemImage: "lock.shield")
            }
            .foregroundStyle(.red)
        }
    }

    private var dictationSection: some View {
        Button {
            manager.toggleDictation()
        } label: {
            Label(
                manager.isDictating ? "Stop Dictation" : "Start Dictation",
                systemImage: manager.isDictating ? "stop.circle.fill" : "mic.circle"
            )
        }
        .badge(Text("Ctrl+Shift+Space").font(.caption2))
        .disabled(!manager.transcriptionEngine.isModelLoaded)
    }

    @ViewBuilder
    private var transcribingSection: some View {
        if manager.transcriptionEngine.isTranscribing {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Transcribing...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
        }
    }

    @ViewBuilder
    private var repasteSection: some View {
        if !manager.lastResult.isEmpty {
            Button {
                Task {
                    await manager.rePasteLast()
                }
            } label: {
                Label("Re-paste Last", systemImage: "doc.on.clipboard")
            }
            .badge(Text("Ctrl+Shift+V").font(.caption2))
        }
    }

    @ViewBuilder
    private var lastTranscriptionSection: some View {
        if !manager.lastResult.isEmpty {
            Button {
                // Copy full text to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(manager.lastResult, forType: .string)
                manager.statusMessage = "Copied to clipboard"
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last transcription:")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(String(manager.lastResult.prefix(120)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .buttonStyle(.plain)
        } else {
            Text("No transcriptions yet")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)
        }
    }

    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button {
                openWindow(id: "history")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("History...", systemImage: "clock.arrow.circlepath")
            }

            Button {
                openWindow(id: "settings")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Settings...", systemImage: "gear")
            }
        }
    }

    private var quitSection: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit Scribe", systemImage: "power")
        }
        .keyboardShortcut("q")
    }
}

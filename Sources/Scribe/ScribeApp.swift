import SwiftUI

@main
struct ScribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var manager = DictationManager()

    var body: some Scene {
        MenuBarExtra("Scribe", systemImage: manager.isDictating ? "mic.fill" : "mic") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Scribe")
                    .font(.headline)

                Text(manager.transcriptionEngine.loadingStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !manager.statusMessage.isEmpty {
                    Text(manager.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Divider()

                // Accessibility permission check
                if !manager.checkAccessibilityPermission() {
                    Button("Grant Accessibility Access") {
                        manager.requestAccessibilityPermission()
                    }
                    .foregroundStyle(.red)
                }

                Button(manager.isDictating ? "Stop Dictation (Ctrl+Shift+Space)" : "Start Dictation (Ctrl+Shift+Space)") {
                    manager.toggleDictation()
                }
                .disabled(!manager.transcriptionEngine.isModelLoaded)

                if !manager.lastResult.isEmpty {
                    Button("Re-paste Last (Ctrl+Shift+V)") {
                        Task {
                            await manager.rePasteLast()
                        }
                    }

                    Divider()

                    Text("Last: \(String(manager.lastResult.prefix(100)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(4)
            .task {
                await manager.setup()
            }
        }
    }
}

import SwiftUI

@main
struct ScribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var manager = DictationManager()

    var body: some Scene {
        MenuBarExtra("Scribe", systemImage: manager.isDictating ? "mic.fill" : "mic") {
            MenuBarView()
                .environment(manager)
                .environment(manager.historyStore)
                .task {
                    await manager.setup()
                }
        }

        Window("Scribe History", id: "history") {
            HistoryView()
                .environment(manager)
                .environment(manager.historyStore)
        }
        .defaultSize(width: 500, height: 400)

        Window("Scribe Settings", id: "settings") {
            SettingsView()
                .environment(manager)
        }
        .defaultSize(width: 450, height: 350)
    }
}

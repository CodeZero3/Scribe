import SwiftUI

@main
struct ScribeApp: App {
    @State private var manager = DictationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(manager)
                    .environment(manager.historyStore)
            } else {
                OnboardingView()
            }
        }
        .defaultSize(width: 700, height: 500)

        Window("Review Transcription", id: "review") {
            ReviewPopup()
                .environment(manager)
        }
        .defaultSize(width: 500, height: 350)
    }
}

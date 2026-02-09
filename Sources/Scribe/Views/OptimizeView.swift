import SwiftUI

struct OptimizeView: View {
    @Environment(DictationManager.self) private var manager
    @AppStorage("geminiAPIKey") private var geminiAPIKey = ""

    var body: some View {
        @Bindable var optimizer = manager.promptOptimizer
        Form {
            // MARK: - Header

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.title)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI-Powered Optimization")
                            .font(.headline)
                        Text("Choose how your dictated text gets refined")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Mode Selection

            Section("Optimization Mode") {
                ForEach(OptimizationMode.allCases) { mode in
                    modeCard(mode)
                }
            }

            // MARK: - Configuration

            Section("Configuration") {
                SecureField("Gemini API Key", text: $geminiAPIKey)
                    .textFieldStyle(.roundedBorder)

                Link("Get free API key from Google AI Studio",
                     destination: URL(string: "https://aistudio.google.com/apikey")!)
                    .font(.caption)

                Text("Toggle modes on/off using the sidebar switches or the cards above. Dictated text is automatically optimized through all enabled modes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        .navigationTitle("Optimize")
    }

    // MARK: - Mode Card

    @ViewBuilder
    private func modeCard(_ mode: OptimizationMode) -> some View {
        let isEnabled = manager.promptOptimizer.isModeEnabled(mode)
        let isLocked = mode.requiresUnlock && !manager.promptOptimizer.optimizationUnlocked

        HStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.title2)
                .foregroundColor(isLocked ? .secondary : .blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(mode.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if !mode.requiresUnlock {
                        Text("Free")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
                Text(mode.detailedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            } else {
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in manager.promptOptimizer.toggleMode(mode) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
        .opacity(isLocked ? 0.6 : 1.0)
    }
}

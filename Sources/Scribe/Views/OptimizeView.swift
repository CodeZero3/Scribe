import SwiftUI

struct OptimizeView: View {
    @Environment(DictationManager.self) private var manager
    @AppStorage("geminiAPIKey") private var geminiAPIKey = ""
    @AppStorage("autoOptimize") private var autoOptimize = false

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

                Toggle("Auto-optimize dictations", isOn: $autoOptimize)
                    .disabled(geminiAPIKey.isEmpty)

                Text("When enabled, dictated text is automatically optimized using the selected mode before copying to clipboard.")
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
        let isSelected = manager.promptOptimizer.selectedMode == mode
        let isLocked = mode.requiresUnlock && !manager.promptOptimizer.optimizationUnlocked

        Button {
            if !isLocked {
                manager.promptOptimizer.selectedMode = mode
            }
        } label: {
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
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.6 : 1.0)
    }
}

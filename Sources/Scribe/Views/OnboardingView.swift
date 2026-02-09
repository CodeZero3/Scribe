@preconcurrency import AVFoundation
import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var micGranted = false
    @State private var accessibilityGranted = false
    @State private var permissionCheckTimer: Timer?

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: microphoneStep
                case 2: accessibilityStep
                case 3: readyStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)

            // Step indicators
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(width: 480, height: 400)
        .onAppear {
            checkCurrentPermissions()
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "mic.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Scribe")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Free, local voice-to-text for macOS")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("All processing happens on your Mac.\nNo cloud, no subscriptions.")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            Spacer()

            Button {
                withAnimation { currentStep = 1 }
            } label: {
                Text("Get Started")
                    .frame(maxWidth: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Step 2: Microphone Permission

    private var microphoneStep: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: micGranted ? "checkmark.circle.fill" : "mic.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(micGranted ? Color.green : Color.accentColor)

            Text("Microphone Access")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Scribe needs your microphone to hear your voice.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if micGranted {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            } else {
                Button {
                    requestMicrophoneAccess()
                } label: {
                    Text("Grant Microphone Access")
                        .frame(maxWidth: 220)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }

            Spacer()

            Button {
                withAnimation { currentStep = 2 }
            } label: {
                Text("Next")
                    .frame(maxWidth: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(!micGranted)
        }
    }

    // MARK: - Step 3: Accessibility Permission

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(accessibilityGranted ? Color.green : Color.accentColor)

            Text("Accessibility Access")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Scribe needs Accessibility access to type text\nin your apps and register global hotkeys.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if accessibilityGranted {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            } else {
                Button {
                    openAccessibilitySettings()
                } label: {
                    Text("Open System Settings")
                        .frame(maxWidth: 220)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Text("Toggle Scribe on, then come back here.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                withAnimation { currentStep = 3 }
            } label: {
                Text("Next")
                    .frame(maxWidth: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(!accessibilityGranted)
        }
        .onAppear {
            startAccessibilityPolling()
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
        }
    }

    // MARK: - Step 4: Ready

    private var readyStep: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("You're all set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 10) {
                Label {
                    Text("Press **Ctrl+Shift+Space** to start dictating")
                } icon: {
                    Image(systemName: "keyboard")
                }
                .font(.body)

                Label {
                    Text("Press **Ctrl+Shift+V** to re-paste the last dictation")
                } icon: {
                    Image(systemName: "doc.on.clipboard")
                }
                .font(.body)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)

            Text("The Whisper model will download in the background (~142MB)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Start Using Scribe")
                    .frame(maxWidth: 220)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func checkCurrentPermissions() {
        // Check microphone
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            micGranted = true
        default:
            micGranted = false
        }

        // Check accessibility
        accessibilityGranted = AXIsProcessTrusted()
    }

    private func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                micGranted = granted
            }
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startAccessibilityPolling() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                accessibilityGranted = AXIsProcessTrusted()
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
        // Close the onboarding window
        NSApplication.shared.windows
            .filter { $0.title == "Welcome to Scribe" || $0.identifier?.rawValue == "onboarding" }
            .forEach { $0.close() }
    }
}

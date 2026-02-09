@preconcurrency import AVFoundation
import SwiftUI

struct SettingsView: View {
    @Environment(DictationManager.self) private var manager
    @State private var availableDevices: [AudioDeviceInfo] = []

    var body: some View {
        @Bindable var mgr = manager
        Form {
            // MARK: - Audio Input

            Section("Microphone") {
                Picker("Input Device", selection: $mgr.selectedDeviceID) {
                    Text("System Default").tag("")
                    ForEach(availableDevices) { device in
                        Text(device.name).tag(device.id)
                    }
                }
            }

            // MARK: - Model

            Section("Whisper Model") {
                Picker("Model", selection: $mgr.selectedModel) {
                    Text("tiny.en (fastest)").tag("tiny.en")
                    Text("base.en (balanced)").tag("base.en")
                    Text("small.en (best quality)").tag("small.en")
                }
                Text("Changing the model requires a restart to take effect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Text Cleanup

            Section("Text Cleanup") {
                Toggle("Clean up transcriptions", isOn: $mgr.enableCleanup)
                Text("Removes filler words (um, uh, like...), fixes punctuation and capitalization.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Behavior

            Section("Behavior") {
                Toggle("Auto-paste after dictation", isOn: $mgr.autoPaste)
                Toggle("Review before inserting", isOn: $mgr.reviewBeforeInsert)
                Text("Show a popup to review and edit the transcription before it is inserted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Hotkeys (read-only)

            Section("Hotkeys") {
                LabeledContent("Push-to-Talk", value: "Hold Ctrl + CapsLock")
                LabeledContent("Re-paste Last", value: "Ctrl + Shift + V")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        .navigationTitle("Settings")
        .onAppear {
            loadAudioDevices()
        }
    }

    private func loadAudioDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        )
        availableDevices = discoverySession.devices.map { device in
            AudioDeviceInfo(id: device.uniqueID, name: device.localizedName)
        }
    }
}

struct AudioDeviceInfo: Identifiable {
    let id: String
    let name: String
}

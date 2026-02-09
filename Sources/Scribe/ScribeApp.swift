import SwiftUI

@main
struct ScribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var audioRecorder = AudioRecorder()
    @State private var transcriptionEngine = TranscriptionEngine()

    var body: some Scene {
        MenuBarExtra("Scribe", systemImage: audioRecorder.isRecording ? "mic.fill" : "mic") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Scribe - Voice to Text")
                    .font(.headline)

                Text("Status: \(transcriptionEngine.loadingStatus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                if audioRecorder.isRecording {
                    Button("Stop Dictation") {
                        stopDictation()
                    }
                } else {
                    Button("Start Dictation") {
                        startDictation()
                    }
                    .disabled(!transcriptionEngine.isModelLoaded)
                }

                if transcriptionEngine.isTranscribing {
                    Text("Transcribing...")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if !transcriptionEngine.lastTranscription.isEmpty {
                    Divider()
                    Text("Last: \(String(transcriptionEngine.lastTranscription.prefix(100)))")
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
                await transcriptionEngine.loadModel()
            }
        }
    }

    private func startDictation() {
        do {
            try audioRecorder.startRecording()
        } catch {
            transcriptionEngine.lastTranscription = "[Mic error: \(error.localizedDescription)]"
        }
    }

    private func stopDictation() {
        let samples = audioRecorder.stopRecording()
        guard !samples.isEmpty else {
            transcriptionEngine.lastTranscription = "[No audio captured]"
            return
        }
        Task {
            let text = await transcriptionEngine.transcribe(audioSamples: samples)
            // Copy transcription to clipboard for easy pasting
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }
    }
}

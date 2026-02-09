import AppKit
import Foundation

@Observable
@MainActor
final class DictationManager {
    let audioRecorder = AudioRecorder()
    let transcriptionEngine = TranscriptionEngine()
    let hotkeyManager = HotkeyManager()
    let textInserter = TextInserter()

    var lastResult = ""
    var isDictating = false
    var statusMessage = ""

    func setup() async {
        // Load whisper model
        await transcriptionEngine.loadModel()

        // Register hotkeys
        hotkeyManager.onToggleDictation = { [weak self] in
            self?.toggleDictation()
        }
        hotkeyManager.onRepaste = { [weak self] in
            Task { @MainActor in
                await self?.rePasteLast()
            }
        }
        hotkeyManager.registerHotkeys()
    }

    func toggleDictation() {
        if isDictating {
            stopDictation()
        } else {
            startDictation()
        }
    }

    private func startDictation() {
        guard transcriptionEngine.isModelLoaded else {
            statusMessage = "Model not ready"
            return
        }
        do {
            try audioRecorder.startRecording()
            isDictating = true
            statusMessage = "Recording..."
        } catch {
            statusMessage = "Mic error: \(error.localizedDescription)"
        }
    }

    private func stopDictation() {
        let samples = audioRecorder.stopRecording()
        isDictating = false

        guard !samples.isEmpty else {
            statusMessage = "No audio captured"
            return
        }

        statusMessage = "Transcribing..."
        Task {
            let text = await transcriptionEngine.transcribe(audioSamples: samples)
            guard !text.isEmpty && !text.hasPrefix("[") else {
                statusMessage = "No speech detected"
                return
            }
            lastResult = text
            statusMessage = "Done - inserted text"
            await textInserter.insertText(text)
        }
    }

    func rePasteLast() async {
        guard !lastResult.isEmpty else {
            statusMessage = "Nothing to re-paste"
            return
        }
        await textInserter.insertText(lastResult)
        statusMessage = "Re-pasted last dictation"
    }

    /// Check if Accessibility permission is granted (needed for text insertion)
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Prompt user to grant Accessibility permission
    func requestAccessibilityPermission() {
        // Use the string value directly to avoid Swift 6 concurrency error on the C global
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: kCFBooleanTrue!] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

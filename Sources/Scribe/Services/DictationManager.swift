import AppKit
import Foundation

@Observable
@MainActor
final class DictationManager {
    let audioRecorder = AudioRecorder()
    let transcriptionEngine = TranscriptionEngine()
    let hotkeyManager = HotkeyManager()
    let textInserter = TextInserter()
    let historyStore = HistoryStore()
    let textCleanup = TextCleanup()

    var lastResult = ""
    var isDictating = false
    var statusMessage = ""

    // Settings
    var selectedDeviceID = ""
    var selectedModel = "base.en"
    var autoPaste = true
    var enableCleanup = true
    var reviewBeforeInsert = false

    // Review popup state
    var pendingCleanupResult: CleanupResult?
    var showReviewPopup = false

    /// Callback set by ScribeApp to open the review window
    @ObservationIgnored
    var onRequestReview: (() -> Void)?

    // Duration tracking
    private var recordingStartTime: Date?
    private var pendingOriginalText: String = ""

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
            recordingStartTime = Date()
            statusMessage = "Recording..."
        } catch {
            statusMessage = "Mic error: \(error.localizedDescription)"
        }
    }

    private func stopDictation() {
        let samples = audioRecorder.stopRecording()
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        isDictating = false
        recordingStartTime = nil

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

            // Run text cleanup if enabled
            let cleanupResult = enableCleanup ? textCleanup.cleanup(text) : nil
            let finalText = cleanupResult?.cleaned ?? text

            lastResult = finalText
            pendingOriginalText = text

            // Save to history (save the final/cleaned text)
            historyStore.addRecord(text: finalText, duration: duration)

            // Determine insertion method
            if reviewBeforeInsert {
                // Show review popup
                pendingCleanupResult = cleanupResult ?? CleanupResult(
                    original: text, cleaned: text, changes: []
                )
                showReviewPopup = true
                statusMessage = "Review transcription..."
                onRequestReview?()
            } else if autoPaste {
                await textInserter.insertText(finalText)
                statusMessage = "Done - inserted text"
            } else {
                statusMessage = "Done - text ready"
            }
        }
    }

    // MARK: - Review popup actions

    /// Insert the edited/reviewed text from the review popup
    func insertReviewed(text: String) {
        Task {
            await textInserter.insertText(text)
            lastResult = text
            pendingCleanupResult = nil
            showReviewPopup = false
            statusMessage = "Done - inserted reviewed text"
        }
    }

    /// Insert the original (uncleaned) text
    func insertOriginal() {
        Task {
            let original = pendingCleanupResult?.original ?? pendingOriginalText
            await textInserter.insertText(original)
            lastResult = original
            pendingCleanupResult = nil
            showReviewPopup = false
            statusMessage = "Done - inserted original text"
        }
    }

    /// Cancel the review without inserting anything
    func cancelReview() {
        pendingCleanupResult = nil
        showReviewPopup = false
        statusMessage = "Insertion cancelled"
    }

    func rePasteLast() async {
        guard !lastResult.isEmpty else {
            statusMessage = "Nothing to re-paste"
            return
        }
        await textInserter.insertText(lastResult)
        statusMessage = "Re-pasted last dictation"
    }

    // MARK: - Permissions

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

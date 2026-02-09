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
        NSLog("[Scribe] DictationManager.setup() called")
        // Load whisper model
        await transcriptionEngine.loadModel()
        NSLog("[Scribe] Model load finished, status: %@", transcriptionEngine.loadingStatus)

        // Register hotkeys — push-to-talk (Ctrl+CapsLock)
        hotkeyManager.onStartDictation = { [weak self] in
            self?.startDictation()
        }
        hotkeyManager.onStopDictation = { [weak self] in
            if self?.isDictating == true {
                self?.stopDictation()
            }
        }
        hotkeyManager.onRepaste = { [weak self] in
            Task { @MainActor in
                await self?.rePasteLast()
            }
        }
        hotkeyManager.registerHotkeys()
    }

    func toggleDictation() {
        NSLog("[Scribe] toggleDictation called, isDictating: %@", isDictating ? "true" : "false")
        if isDictating {
            stopDictation()
        } else {
            startDictation()
        }
    }

    func startDictation() {
        guard !isDictating else { return }
        guard transcriptionEngine.isModelLoaded else {
            NSLog("[Scribe] startDictation: Model not ready")
            statusMessage = "Model not ready"
            return
        }
        do {
            NSLog("[Scribe] startDictation: Starting recording...")
            try audioRecorder.startRecording()
            isDictating = true
            recordingStartTime = Date()
            statusMessage = "Recording..."
            NSLog("[Scribe] startDictation: Recording started")
        } catch {
            NSLog("[Scribe] startDictation error: %@", error.localizedDescription)
            statusMessage = "Mic error: \(error.localizedDescription)"
        }
    }

    func stopDictation() {
        guard isDictating else { return }
        NSLog("[Scribe] stopDictation called")
        let samples = audioRecorder.stopRecording()
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        isDictating = false
        recordingStartTime = nil

        NSLog("[Scribe] stopDictation: Got %d samples", samples.count)
        guard !samples.isEmpty else {
            statusMessage = "No audio captured"
            return
        }

        statusMessage = "Transcribing..."
        Task {
            let text = await transcriptionEngine.transcribe(audioSamples: samples)
            NSLog("[Scribe] Transcription result: %@", text)
            guard !text.isEmpty && !text.hasPrefix("[") else {
                statusMessage = "No speech detected"
                return
            }

            // Run text cleanup if enabled
            let cleanupResult = enableCleanup ? textCleanup.cleanup(text) : nil
            let finalText = cleanupResult?.cleaned ?? text

            lastResult = finalText
            pendingOriginalText = text

            // Always copy to clipboard
            copyToClipboard(finalText)

            // Save to history
            historyStore.addRecord(text: finalText, duration: duration)

            // Determine insertion method
            if reviewBeforeInsert {
                pendingCleanupResult = cleanupResult ?? CleanupResult(
                    original: text, cleaned: text, changes: []
                )
                showReviewPopup = true
                statusMessage = "Review transcription..."
                onRequestReview?()
            } else {
                statusMessage = "Done - copied to clipboard"
            }
        }
    }

    // MARK: - Clipboard

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - Review popup actions

    func insertReviewed(text: String) {
        Task {
            await textInserter.insertText(text)
            lastResult = text
            pendingCleanupResult = nil
            showReviewPopup = false
            statusMessage = "Done - inserted reviewed text"
        }
    }

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
        copyToClipboard(lastResult)
        statusMessage = "Copied to clipboard"
    }

    // MARK: - Permissions

    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: kCFBooleanTrue!] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

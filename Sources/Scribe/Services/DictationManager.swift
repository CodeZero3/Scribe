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
    let promptOptimizer = PromptOptimizer()

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

    // Warm encouragement messages during recording
    private var warmMessageTimer: Timer?
    private var warmMessageIndex = 0
    private let warmMessages = [
        "Listening...",
        "Just speak naturally, I'll handle the rest",
        "Take your time...",
        "Don't worry about structure, that's my job",
        "Keep going, you're doing great...",
        "I'll clean everything up for you",
        "Say it however feels natural...",
    ]

    func setup() async {
        Self.log("DictationManager.setup() called")
        // Load whisper model
        await transcriptionEngine.loadModel()
        Self.log("Model load finished, status: \(transcriptionEngine.loadingStatus), isModelLoaded: \(transcriptionEngine.isModelLoaded)")

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
        Self.log("toggleDictation called, isDictating: \(isDictating)")
        if isDictating {
            stopDictation()
        } else {
            startDictation()
        }
    }

    func startDictation() {
        guard !isDictating else {
            Self.log("startDictation: already dictating, skipping")
            return
        }
        guard transcriptionEngine.isModelLoaded else {
            Self.log("startDictation: Model not ready")
            statusMessage = "Model not ready"
            return
        }
        do {
            Self.log("startDictation: Starting recording...")
            try audioRecorder.startRecording()
            isDictating = true
            recordingStartTime = Date()
            statusMessage = "Recording..."
            Self.log("startDictation: Recording started successfully")

            // Start warm message rotation
            if promptOptimizer.isConfigured {
                warmMessageIndex = 0
                warmMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self, self.isDictating else { return }
                        self.statusMessage = self.warmMessages[self.warmMessageIndex % self.warmMessages.count]
                        self.warmMessageIndex += 1
                    }
                }
            }
        } catch {
            Self.log("startDictation ERROR: \(error.localizedDescription)")
            statusMessage = "Mic error: \(error.localizedDescription)"
        }
    }

    // MARK: - Debug Logging

    private static let logFile: URL = {
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/scribe_debug.log")
        FileManager.default.createFile(atPath: path.path, contents: nil)
        return path
    }()

    static func log(_ msg: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] \(msg)\n"
        print("[Scribe] \(msg)")
        if let data = line.data(using: .utf8),
           let fh = try? FileHandle(forWritingTo: logFile) {
            fh.seekToEndOfFile()
            fh.write(data)
            fh.closeFile()
        }
    }

    func stopDictation() {
        guard isDictating else { return }
        Self.log("stopDictation called")
        warmMessageTimer?.invalidate()
        warmMessageTimer = nil
        let samples = audioRecorder.stopRecording()
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        isDictating = false
        recordingStartTime = nil

        Self.log("stopDictation: Got \(samples.count) samples")
        guard !samples.isEmpty else {
            statusMessage = "No audio captured"
            Self.log("stopDictation: NO AUDIO — 0 samples!")
            return
        }

        statusMessage = "Transcribing..."
        Task {
            let text = await transcriptionEngine.transcribe(audioSamples: samples)
            Self.log("Transcription result: \(text.prefix(100))")
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

    // MARK: - Prompt Optimization

    @discardableResult
    func optimizeText(_ text: String, mode: OptimizationMode, parentId: String) async -> DictationRecord? {
        statusMessage = "Optimizing..."
        let result = await promptOptimizer.optimize(text, mode: mode)
        guard result != text else {
            statusMessage = "Optimization failed - using original"
            return nil
        }
        statusMessage = "Optimized - copied to clipboard"
        copyToClipboard(result)
        let record = historyStore.addOptimizedRecord(
            text: result, parentId: parentId, mode: mode.rawValue
        )
        return record
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

import Foundation
import WhisperKit

/// Sendable wrapper for WhisperKit since it is not Sendable but is thread-safe in practice.
private final class WhisperKitBox: @unchecked Sendable {
    let kit: WhisperKit
    init(_ kit: WhisperKit) { self.kit = kit }
}

@Observable
@MainActor
final class TranscriptionEngine {
    var isTranscribing = false
    var lastTranscription = ""
    var isModelLoaded = false
    var loadingStatus = "Not loaded"

    private var whisperBox: WhisperKitBox?

    func loadModel() async {
        loadingStatus = "Loading model..."
        do {
            // WhisperKit handles model download automatically
            let config = WhisperKitConfig(model: "base.en", verbose: false, logLevel: .none)
            let kit = try await WhisperKit(config)
            whisperBox = WhisperKitBox(kit)
            isModelLoaded = true
            loadingStatus = "Model ready"
        } catch {
            loadingStatus = "Error: \(error.localizedDescription)"
            isModelLoaded = false
        }
    }

    func transcribe(audioSamples: [Float]) async -> String {
        guard let box = whisperBox else {
            return "[Model not loaded]"
        }

        isTranscribing = true
        defer { isTranscribing = false }

        do {
            let results: [TranscriptionResult] = try await box.kit.transcribe(audioArray: audioSamples)
            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            lastTranscription = text.isEmpty ? "[No speech detected]" : text
            return lastTranscription
        } catch {
            lastTranscription = "[Error: \(error.localizedDescription)]"
            return lastTranscription
        }
    }
}

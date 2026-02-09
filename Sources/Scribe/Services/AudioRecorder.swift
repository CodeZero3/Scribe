@preconcurrency import AVFoundation
import Foundation

@Observable
@MainActor
final class AudioRecorder {
    var isRecording = false
    private var audioEngine = AVAudioEngine()
    private var audioSamples: [Float] = []

    func startRecording() throws {
        audioSamples = []

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install a tap on the input node to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            // Convert to 16kHz mono Float32 for WhisperKit
            let samples = self.convertToWhisperFormat(buffer: buffer, from: recordingFormat)
            Task { @MainActor in
                self.audioSamples.append(contentsOf: samples)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() -> [Float] {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        return audioSamples
    }

    // nonisolated because this is called from the audio tap callback (non-main-actor context)
    nonisolated private func convertToWhisperFormat(buffer: AVAudioPCMBuffer, from format: AVAudioFormat) -> [Float] {
        // WhisperKit expects 16kHz mono Float32
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            return []
        }

        // If already in the target format, just copy samples directly
        if format.sampleRate == 16000 && format.channelCount == 1 && format.commonFormat == .pcmFormatFloat32 {
            guard let channelData = buffer.floatChannelData?[0] else { return [] }
            return Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        }

        guard let converter = AVAudioConverter(from: format, to: targetFormat) else {
            return []
        }

        let ratio = 16000.0 / format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard outputFrameCount > 0,
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else {
            return []
        }

        var error: NSError?
        // Use nonisolated(unsafe) local to avoid sendable capture warnings
        nonisolated(unsafe) var consumed = false
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard error == nil, let channelData = outputBuffer.floatChannelData?[0] else {
            return []
        }

        return Array(UnsafeBufferPointer(start: channelData, count: Int(outputBuffer.frameLength)))
    }
}

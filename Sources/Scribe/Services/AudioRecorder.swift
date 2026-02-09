@preconcurrency import AVFoundation
import Foundation

@Observable
@MainActor
final class AudioRecorder {
    var isRecording = false
    private var audioEngine = AVAudioEngine()

    /// Thread-safe sample buffer — written from audio thread, read from main thread
    private let sampleBuffer = SampleBuffer()

    func startRecording() throws {
        sampleBuffer.reset()

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        NSLog("[Scribe] AudioRecorder: format = %@ Hz, %d ch", "\(recordingFormat.sampleRate)", recordingFormat.channelCount)

        // Install tap via nonisolated helper so the closure doesn't inherit @MainActor
        Self.installAudioTap(on: inputNode, format: recordingFormat, sampleBuffer: sampleBuffer)

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() -> [Float] {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        let samples = sampleBuffer.drain()
        NSLog("[Scribe] AudioRecorder: drained %d samples", samples.count)
        return samples
    }

    /// Install audio tap in a nonisolated context so the closure runs freely on the audio thread.
    nonisolated private static func installAudioTap(
        on node: AVAudioNode,
        format: AVAudioFormat,
        sampleBuffer: SampleBuffer
    ) {
        node.installTap(onBus: 0, bufferSize: 4096, format: format) { pcmBuffer, _ in
            let samples = convertBufferToWhisperFormat(buffer: pcmBuffer, from: format)
            sampleBuffer.append(samples)
        }
    }
}

// MARK: - Audio format conversion (free function, runs on audio thread)

private func convertBufferToWhisperFormat(buffer: AVAudioPCMBuffer, from format: AVAudioFormat) -> [Float] {
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

// MARK: - Thread-safe sample buffer

private final class SampleBuffer: @unchecked Sendable {
    private var samples: [Float] = []
    private let lock = NSLock()

    func append(_ newSamples: [Float]) {
        lock.lock()
        samples.append(contentsOf: newSamples)
        lock.unlock()
    }

    func drain() -> [Float] {
        lock.lock()
        let result = samples
        samples = []
        lock.unlock()
        return result
    }

    func reset() {
        lock.lock()
        samples = []
        lock.unlock()
    }
}

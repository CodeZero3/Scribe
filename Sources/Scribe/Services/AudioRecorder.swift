@preconcurrency import AVFoundation
import CoreAudio
import Foundation
import os

private let audioLogger = Logger(subsystem: "com.scribe.app", category: "AudioRecorder")

@Observable
@MainActor
final class AudioRecorder {
    var isRecording = false

    /// Persistent engine — kept alive between recordings to preserve correct
    /// Bluetooth format negotiation. Destroying and recreating causes the engine
    /// to revert to a stale 44100 Hz default.
    private var audioEngine: AVAudioEngine?

    /// The format successfully used for recording, cached for reuse
    private var confirmedFormat: AVAudioFormat?

    /// Thread-safe sample buffer — written from audio thread, read from main thread
    private let sampleBuffer = SampleBuffer()

    nonisolated private static func debugLog(_ msg: String) {
        audioLogger.info("\(msg)")
    }

    // MARK: - Recording

    func startRecording() throws {
        sampleBuffer.reset()

        let engine: AVAudioEngine
        if let existing = self.audioEngine {
            // Reuse existing engine — preserves correct format negotiation
            engine = existing
            Self.debugLog("Reusing existing engine")
        } else {
            // First recording or after reset — create new engine
            engine = AVAudioEngine()
            self.audioEngine = engine
            Self.debugLog("Created new engine")
        }

        let inputNode = engine.inputNode
        let hwFormat = Self.queryHardwareInputFormat()
        let engineFormat = inputNode.outputFormat(forBus: 0)

        Self.debugLog("startRecording: hw=\(hwFormat?.sampleRate ?? 0) engine=\(engineFormat.sampleRate)")

        // Pick the best format: confirmed > hardware (if matches engine) > engine
        let tapFormat: AVAudioFormat
        if let confirmed = confirmedFormat {
            tapFormat = confirmed
            Self.debugLog("Using confirmed format: \(confirmed.sampleRate) Hz")
        } else if let hw = hwFormat, abs(engineFormat.sampleRate - hw.sampleRate) < 1 {
            tapFormat = hw
            Self.debugLog("Formats agree: \(hw.sampleRate) Hz")
        } else {
            // Mismatch — use engine format (safe, avoids crash).
            // If this produces 0 samples, the zero-sample check will reset the engine.
            tapFormat = engineFormat
            Self.debugLog("Format mismatch — using engine format \(engineFormat.sampleRate) Hz (will monitor)")
        }

        Self.installAudioTap(on: inputNode, format: tapFormat, sampleBuffer: sampleBuffer)
        engine.prepare()
        try engine.start()
        isRecording = true

        // Monitor for 0-sample condition
        scheduleZeroSampleCheck(tapFormat: tapFormat)
    }

    func stopRecording() -> [Float] {
        // Remove tap but keep engine alive for reuse
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        // Do NOT nil out audioEngine — keep it for next recording
        isRecording = false
        let samples = sampleBuffer.drain()
        Self.debugLog("stopRecording: drained \(samples.count) samples")
        return samples
    }

    // MARK: - Zero-sample detection with engine reset

    private func scheduleZeroSampleCheck(tapFormat: AVAudioFormat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.isRecording else { return }
            let count = self.sampleBuffer.count
            if count > 0 {
                // Working! Cache this format for future recordings
                self.confirmedFormat = tapFormat
                Self.debugLog("Capture confirmed: \(count) samples — cached format \(tapFormat.sampleRate) Hz")
            } else {
                // 0 samples — the engine/format combo isn't working.
                // Destroy engine completely and retry with a fresh one.
                Self.debugLog("WARNING: 0 samples after 1.5s — resetting engine")
                self.audioEngine?.inputNode.removeTap(onBus: 0)
                self.audioEngine?.stop()
                self.audioEngine = nil
                self.confirmedFormat = nil

                do {
                    try self.startRecording()
                } catch {
                    Self.debugLog("Reset retry failed: \(error)")
                }
            }
        }
    }

    // MARK: - CoreAudio hardware format query

    /// Query the actual hardware input format via CoreAudio.
    /// AVAudioEngine.inputNode.outputFormat can report a wrong sample rate
    /// (e.g. 44100 Hz) when a Bluetooth device is actually running at 16000 Hz.
    nonisolated private static func queryHardwareInputFormat() -> AVAudioFormat? {
        var defaultInputID = AudioDeviceID(0)
        var propSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &propSize, &defaultInputID
        )
        guard status == noErr, defaultInputID != kAudioObjectUnknown else { return nil }

        var formatAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamFormat,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var streamFormat = AudioStreamBasicDescription()
        propSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let fmtStatus = AudioObjectGetPropertyData(
            defaultInputID, &formatAddress, 0, nil, &propSize, &streamFormat
        )
        guard fmtStatus == noErr,
              streamFormat.mSampleRate > 0,
              streamFormat.mChannelsPerFrame > 0 else { return nil }

        return AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: streamFormat.mSampleRate,
            channels: AVAudioChannelCount(streamFormat.mChannelsPerFrame),
            interleaved: false
        )
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

    /// Read sample count without draining — used for zero-sample detection
    var count: Int {
        lock.lock()
        let c = samples.count
        lock.unlock()
        return c
    }
}

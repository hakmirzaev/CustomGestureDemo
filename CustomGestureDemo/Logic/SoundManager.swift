/*
 SoundManager.swift
 CustomGestureDemo

 Generates and plays spatial feedback tones for gesture events.
 Tones are synthesized in memory (no bundled audio files needed).
*/

import AVFoundation

/// Generates simple sine-wave tones in memory and plays them as spatial feedback.
///
/// Different frequencies are used for different gesture events:
/// - **Gesture detected**: 880 Hz (A5) — bright, clear
/// - **Pinch**: 1320 Hz (E6) — short, high
/// - **Throw**: 440 Hz (A4) — lower, longer
final class SoundManager: @unchecked Sendable {

    /// Shared singleton instance.
    nonisolated(unsafe) static let shared = SoundManager()

    // MARK: - Audio Players

    private let gesturePlayer: AVAudioPlayer?
    private let pinchPlayer: AVAudioPlayer?
    private let throwPlayer: AVAudioPlayer?

    // MARK: - Initialization

    private init() {
        gesturePlayer = Self.makeTone(frequency: 880, duration: 0.12, volume: 0.4)
        pinchPlayer = Self.makeTone(frequency: 1320, duration: 0.06, volume: 0.3)
        throwPlayer = Self.makeTone(frequency: 440, duration: 0.2, volume: 0.5)
    }

    // MARK: - Playback

    func playGestureDetected() {
        gesturePlayer?.currentTime = 0
        gesturePlayer?.play()
    }

    func playPinch() {
        pinchPlayer?.currentTime = 0
        pinchPlayer?.play()
    }

    func playThrow() {
        throwPlayer?.currentTime = 0
        throwPlayer?.play()
    }

    // MARK: - Tone Generation

    /// Creates an `AVAudioPlayer` loaded with a synthesized sine-wave WAV.
    private static func makeTone(
        frequency: Double,
        duration: Double,
        volume: Float
    ) -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let count = Int(sampleRate * duration)
        var pcm = Data(capacity: count * 2)

        for i in 0..<count {
            let t = Double(i) / sampleRate
            // Smooth envelope (5 ms fade-in/out) to avoid clicks.
            let envelope = min(1.0, min(t / 0.005, (duration - t) / 0.005))
            let sample = Int16(sin(2.0 * .pi * frequency * t) * Double(volume) * 32767.0 * envelope)
            withUnsafeBytes(of: sample) { pcm.append(contentsOf: $0) }
        }

        let wav = makeWAV(pcmData: pcm, sampleRate: 44100, channels: 1, bitsPerSample: 16)
        let player = try? AVAudioPlayer(data: wav)
        player?.prepareToPlay()
        return player
    }

    /// Constructs a minimal WAV file from raw PCM data.
    private static func makeWAV(
        pcmData: Data,
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int
    ) -> Data {
        var d = Data()
        let dataSize = UInt32(pcmData.count)

        func append<T>(_ value: T) {
            withUnsafeBytes(of: value) { d.append(contentsOf: $0) }
        }

        // RIFF header
        d.append(contentsOf: "RIFF".utf8)
        append(UInt32(36) + dataSize)
        d.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        d.append(contentsOf: "fmt ".utf8)
        append(UInt32(16))
        append(UInt16(1)) // PCM format
        append(UInt16(channels))
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * channels * bitsPerSample / 8))
        append(UInt16(channels * bitsPerSample / 8))
        append(UInt16(bitsPerSample))

        // data chunk
        d.append(contentsOf: "data".utf8)
        append(dataSize)
        d.append(pcmData)

        return d
    }
}

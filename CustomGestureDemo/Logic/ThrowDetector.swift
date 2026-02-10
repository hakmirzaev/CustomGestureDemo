/*
 ThrowDetector.swift
 CustomGestureDemo

 Wrist velocity tracking for detecting throw gestures.

 Approach: **Hand action classification via velocity analysis**
 While the spider gesture is held, the wrist position is sampled every frame.
 When the wrist velocity exceeds a threshold, a "throw" action is triggered.
 This is a lightweight alternative to Create ML action classification.

 The throw direction is derived from the velocity vector of the wrist,
 giving a natural aiming mechanic — wherever the user flicks their wrist,
 that's where the projectile goes.
*/

import simd

/// Tracks wrist positions over time and detects throw gestures based on velocity.
enum ThrowDetector {

    // MARK: - Types

    /// A single wrist position sample with timestamp.
    struct Sample {
        let position: SIMD3<Float>
        let time: Double
    }

    // MARK: - State

    /// Circular buffer of recent wrist samples for the left hand.
    nonisolated(unsafe) private static var leftSamples: [Sample] = []

    /// Circular buffer of recent wrist samples for the right hand.
    nonisolated(unsafe) private static var rightSamples: [Sample] = []

    // MARK: - Configuration

    /// Maximum number of samples to keep in the buffer.
    private static let maxSamples = 15

    /// Minimum wrist speed (m/s) to classify as a throw.
    private static let throwSpeedThreshold: Float = 1.5

    /// Minimum time between throws to prevent rapid-fire (seconds).
    private static let cooldownDuration: Double = 0.5

    /// Timestamps of last throw per hand.
    nonisolated(unsafe) private static var lastThrowTimeLeft: Double = 0
    nonisolated(unsafe) private static var lastThrowTimeRight: Double = 0

    // MARK: - Public API

    /// Records a wrist position sample.
    /// - Parameters:
    ///   - position: The world-space position of the wrist joint.
    ///   - time: The current time (`CACurrentMediaTime()`).
    ///   - isLeft: Whether this sample is for the left hand.
    static func addSample(position: SIMD3<Float>, time: Double, isLeft: Bool) {
        if isLeft {
            leftSamples.append(Sample(position: position, time: time))
            if leftSamples.count > maxSamples { leftSamples.removeFirst() }
        } else {
            rightSamples.append(Sample(position: position, time: time))
            if rightSamples.count > maxSamples { rightSamples.removeFirst() }
        }
    }

    /// Checks if the recent wrist motion constitutes a throw.
    /// - Parameters:
    ///   - isLeft: Whether to check the left hand.
    ///   - currentTime: The current time for cooldown checking.
    /// - Returns: A tuple of (isThrow, velocity) where velocity is the throw direction.
    static func detectThrow(isLeft: Bool, currentTime: Double) -> (isThrow: Bool, velocity: SIMD3<Float>) {
        let samples = isLeft ? leftSamples : rightSamples
        let lastThrow = isLeft ? lastThrowTimeLeft : lastThrowTimeRight

        // Enforce cooldown.
        guard currentTime - lastThrow > cooldownDuration else { return (false, .zero) }

        // Need at least 5 samples for reliable velocity estimation.
        guard samples.count >= 5 else { return (false, .zero) }

        // Use the last 5 samples to compute velocity.
        let recent = Array(samples.suffix(5))
        let dt = recent.last!.time - recent.first!.time
        guard dt > 0.001 else { return (false, .zero) }

        let displacement = recent.last!.position - recent.first!.position
        let velocity = displacement / Float(dt)
        let speed = simd_length(velocity)

        if speed > throwSpeedThreshold {
            // Record throw time for cooldown.
            if isLeft {
                lastThrowTimeLeft = currentTime
            } else {
                lastThrowTimeRight = currentTime
            }
            return (true, velocity)
        }

        return (false, .zero)
    }

    /// Clears the sample buffer for a hand (call when the gesture deactivates).
    static func reset(isLeft: Bool) {
        if isLeft {
            leftSamples.removeAll()
        } else {
            rightSamples.removeAll()
        }
    }
}

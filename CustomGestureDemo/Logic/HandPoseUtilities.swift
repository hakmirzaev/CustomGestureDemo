/*
 HandPoseUtilities.swift
 CustomGestureDemo

 Shared utility functions for analyzing hand skeleton joint positions.
 Used by all gesture detectors and the visualization system.
*/

import ARKit
import simd

/// Shared utilities for analyzing hand skeleton joint positions.
///
/// These functions form the mathematical foundation for procedural gesture detection.
///
/// **For non-thumb fingers**, the primary heuristic is the **distance-ratio method**:
/// comparing each fingertip's distance from the wrist against the knuckle's distance
/// from the wrist. A ratio > 1.15 = extended, < 1.05 = curled.
///
/// **For the thumb**, which has different biomechanics, we use a **palm-relative method**:
/// measuring the thumb tip's distance from the center of the palm (middle finger knuckle),
/// normalized by hand size. This is more reliable because the thumb naturally rests
/// farther from the wrist than its knuckle, making the standard ratio inaccurate.
///
/// Reference: "Implementing Custom Hand Gestures on Apple Vision" — Daniel T. Perry
enum HandPoseUtilities {

    // MARK: - Position Extraction

    /// Extracts the anchor-relative 3D position of a joint.
    static func position(
        of joint: HandSkeleton.JointName,
        in skeleton: HandSkeleton
    ) -> SIMD3<Float> {
        let t = skeleton.joint(joint).anchorFromJointTransform
        return SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
    }

    /// Computes the world-space position of a joint.
    static func worldPosition(
        of joint: HandSkeleton.JointName,
        handAnchor: HandAnchor,
        skeleton: HandSkeleton
    ) -> SIMD3<Float> {
        let anchorFromJoint = skeleton.joint(joint).anchorFromJointTransform
        let originFromJoint = handAnchor.originFromAnchorTransform * anchorFromJoint
        return SIMD3<Float>(
            originFromJoint.columns.3.x,
            originFromJoint.columns.3.y,
            originFromJoint.columns.3.z
        )
    }

    // MARK: - Standard Finger Analysis (index, middle, ring, little)

    /// Returns the curl ratio for a non-thumb finger: `tipDist / knuckleDist` relative to wrist.
    /// - Values **> 1.15** → extended
    /// - Values **< 1.10** → curled
    static func curlRatio(
        skeleton: HandSkeleton,
        tip: HandSkeleton.JointName,
        knuckle: HandSkeleton.JointName,
        wrist: HandSkeleton.JointName = .wrist
    ) -> Float {
        let tipPos = position(of: tip, in: skeleton)
        let knucklePos = position(of: knuckle, in: skeleton)
        let wristPos = position(of: wrist, in: skeleton)
        let tipDist = simd_distance(tipPos, wristPos)
        let knuckleDist = simd_distance(knucklePos, wristPos)
        guard knuckleDist > 0.001 else { return 1.0 }
        return tipDist / knuckleDist
    }

    /// Returns `true` when a non-thumb finger is extended.
    static func isFingerExtended(
        skeleton: HandSkeleton,
        tip: HandSkeleton.JointName,
        knuckle: HandSkeleton.JointName,
        wrist: HandSkeleton.JointName = .wrist,
        factor: Float = 1.15
    ) -> Bool {
        curlRatio(skeleton: skeleton, tip: tip, knuckle: knuckle, wrist: wrist) > factor
    }

    /// Returns `true` when a non-thumb finger is curled.
    static func isFingerCurled(
        skeleton: HandSkeleton,
        tip: HandSkeleton.JointName,
        knuckle: HandSkeleton.JointName,
        wrist: HandSkeleton.JointName = .wrist,
        factor: Float = 1.10
    ) -> Bool {
        curlRatio(skeleton: skeleton, tip: tip, knuckle: knuckle, wrist: wrist) < factor
    }

    // MARK: - Thumb-Specific Analysis

    /// Returns the thumb curl ratio using a **palm-relative** metric.
    ///
    /// Standard distance-ratio doesn't work for the thumb because the thumb
    /// naturally rests with its tip farther from the wrist than its knuckle.
    ///
    /// Instead, we measure: `thumbTip-to-palmCenter / wrist-to-palmCenter`
    /// where palmCenter = middleFingerKnuckle.
    ///
    /// - Curled (fist): ratio ≈ 0.4–0.7 (thumb tip is near the palm)
    /// - Resting: ratio ≈ 0.7–0.9
    /// - Extended: ratio ≈ 0.9–1.4 (thumb tip is far from the palm)
    static func thumbCurlRatio(skeleton: HandSkeleton) -> Float {
        let thumbTip = position(of: .thumbTip, in: skeleton)
        let palmCenter = position(of: .middleFingerKnuckle, in: skeleton)
        let wrist = position(of: .wrist, in: skeleton)
        let thumbDist = simd_distance(thumbTip, palmCenter)
        let handSize = simd_distance(wrist, palmCenter)
        guard handSize > 0.001 else { return 1.0 }
        return thumbDist / handSize
    }

    /// Returns `true` when the thumb is curled toward the palm.
    static func isThumbCurled(skeleton: HandSkeleton) -> Bool {
        thumbCurlRatio(skeleton: skeleton) < 0.75
    }

    /// Returns `true` when the thumb is extended away from the palm.
    static func isThumbExtended(skeleton: HandSkeleton) -> Bool {
        thumbCurlRatio(skeleton: skeleton) > 0.95
    }

    // MARK: - Pinch Detection

    /// Returns `true` when the thumb tip is touching the specified fingertip.
    /// Uses a distance threshold of 2.5 cm.
    static func isPinching(
        skeleton: HandSkeleton,
        fingerTip: HandSkeleton.JointName,
        threshold: Float = 0.025
    ) -> Bool {
        let thumbTip = position(of: .thumbTip, in: skeleton)
        let otherTip = position(of: fingerTip, in: skeleton)
        return simd_distance(thumbTip, otherTip) < threshold
    }

    // MARK: - V-Shape Check (Peace Sign)

    /// Returns the distance between the index fingertip and middle fingertip.
    /// For a valid peace sign, fingers must be spread apart (V shape).
    static func indexMiddleSpread(skeleton: HandSkeleton) -> Float {
        let indexTip = position(of: .indexFingerTip, in: skeleton)
        let middleTip = position(of: .middleFingerTip, in: skeleton)
        return simd_distance(indexTip, middleTip)
    }
}

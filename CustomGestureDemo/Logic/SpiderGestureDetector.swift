/*
 SpiderGestureDetector.swift
 CustomGestureDemo

 Math-based detection of the Spider-Man web-shooting gesture.

 Approach: **Procedural / distance-ratio heuristic**
 This is the simplest and lowest-latency method for custom gesture detection.

 The Spider-Man gesture requires:
   • Index finger — extended (pointing forward)
   • Little finger — extended (pinky out)
   • Middle finger — curled (folded into palm)
   • Ring finger   — curled (folded into palm)
   • Thumb         — curled (pressing on middle/ring, uses palm-relative detection)
*/

import ARKit

/// Detects the Spider-Man web-shooting gesture using procedural math.
enum SpiderGestureDetector {

    /// Entity name for the spider gesture visualization sphere.
    static let entityName = "spiderSphere"

    // MARK: - Detection

    /// Detects whether the hand skeleton matches the spider-web gesture.
    static func detect(handSkeleton: HandSkeleton) -> Bool {
        // Thumb uses palm-relative method (different biomechanics).
        let thumbCurled = HandPoseUtilities.isThumbCurled(skeleton: handSkeleton)

        // Other fingers use standard distance-ratio method.
        let indexExtended = HandPoseUtilities.isFingerExtended(
            skeleton: handSkeleton,
            tip: .indexFingerTip,
            knuckle: .indexFingerKnuckle
        )
        let middleCurled = HandPoseUtilities.isFingerCurled(
            skeleton: handSkeleton,
            tip: .middleFingerTip,
            knuckle: .middleFingerKnuckle
        )
        let ringCurled = HandPoseUtilities.isFingerCurled(
            skeleton: handSkeleton,
            tip: .ringFingerTip,
            knuckle: .ringFingerKnuckle
        )
        let littleExtended = HandPoseUtilities.isFingerExtended(
            skeleton: handSkeleton,
            tip: .littleFingerTip,
            knuckle: .littleFingerKnuckle
        )

        return thumbCurled && indexExtended && middleCurled && ringCurled && littleExtended
    }
}

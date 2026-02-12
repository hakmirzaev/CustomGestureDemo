/*
 PeaceGestureDetector.swift
 CustomGestureDemo

 Math-based detection of the peace sign (✌️) gesture.

 The peace sign gesture requires:
   • Index finger  — extended (V shape, left prong)
   • Middle finger — extended (V shape, right prong)
   • Ring finger   — curled
   • Little finger  — curled
   • Thumb         — curled (tucked in, uses palm-relative detection)
   • V-shape       — index and middle tips must be spread apart (≥ 4 cm)

 NOTE — GestureKit Integration:
 For production apps, consider using GestureKit (https://github.com/nthState/GestureKit)
 which provides a visual Gesture Composer workflow. See GestureKitIntegration.swift.
*/

import ARKit

/// Detects the peace sign gesture using procedural math.
enum PeaceGestureDetector {

    /// Entity name for the peace gesture visualization sphere.
    static let entityName = "peaceSphere"

    /// Minimum distance (meters) between index and middle tips for a valid V shape.
    private static let minVShapeSpread: Float = 0.04

    // MARK: - Detection

    /// Detects whether the hand skeleton matches the peace sign gesture.
    static func detect(handSkeleton: HandSkeleton) -> Bool {
        // Thumb uses palm-relative method (different biomechanics).
        let thumbCurled = HandPoseUtilities.isThumbCurled(skeleton: handSkeleton)

        // Other fingers use standard distance-ratio method.
        let indexExtended = HandPoseUtilities.isFingerExtended(
            skeleton: handSkeleton,
            tip: .indexFingerTip,
            knuckle: .indexFingerKnuckle
        )
        let middleExtended = HandPoseUtilities.isFingerExtended(
            skeleton: handSkeleton,
            tip: .middleFingerTip,
            knuckle: .middleFingerKnuckle
        )
        let ringCurled = HandPoseUtilities.isFingerCurled(
            skeleton: handSkeleton,
            tip: .ringFingerTip,
            knuckle: .ringFingerKnuckle
        )
        let littleCurled = HandPoseUtilities.isFingerCurled(
            skeleton: handSkeleton,
            tip: .littleFingerTip,
            knuckle: .littleFingerKnuckle
        )

        // V-shape check: index and middle fingertips must be spread apart,
        // not held together side-by-side.
        let hasVShape = HandPoseUtilities.indexMiddleSpread(
            skeleton: handSkeleton
        ) > minVShapeSpread

        return thumbCurled && indexExtended && middleExtended
            && ringCurled && littleCurled && hasVShape
    }
}

/*
 AppModel.swift
 CustomGestureDemo

 Maintains app-wide state shared between windows and the immersive space.
*/

import SwiftUI

// MARK: - Finger State Info

/// Information about a single finger's curl/extension state and pinch status.
struct FingerInfo: Identifiable, Sendable {
    let id: String
    let name: String

    /// Curl ratio metric (interpretation depends on finger type).
    /// For non-thumb: tipDist/knuckleDist relative to wrist. > 1.15 = extended, < 1.05 = curled.
    /// For thumb: thumbTip-to-palmCenter / wrist-to-palmCenter. < 0.75 = curled, > 0.95 = extended.
    var curlRatio: Float

    /// Whether this finger is currently pinching with the thumb.
    var isPinching: Bool

    /// Whether this finger is extended.
    var isExtended: Bool

    /// Whether this finger is curled.
    var isCurled: Bool

    /// Default state for all five fingers (neutral position).
    static let defaultStates: [FingerInfo] = [
        FingerInfo(id: "thumb", name: "Thumb", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "index", name: "Index", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "middle", name: "Middle", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "ring", name: "Ring", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "little", name: "Little", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
    ]
}

// MARK: - App Model

/// Observable app-wide state for settings, gesture detection, and finger analysis.
@Observable
@MainActor
class AppModel {
    // MARK: Settings

    var immersiveSpaceIsShown = false
    var showJointSpheres = true

    // MARK: Active Gestures (updated by GestureVisualizationSystem)

    var leftSpiderGesture = false
    var rightSpiderGesture = false
    var leftPeaceGesture = false
    var rightPeaceGesture = false

    var isSpiderGestureActive: Bool { leftSpiderGesture || rightSpiderGesture }
    var isPeaceGestureActive: Bool { leftPeaceGesture || rightPeaceGesture }

    // MARK: Finger States (updated by GestureVisualizationSystem)

    var leftFingerStates: [FingerInfo] = FingerInfo.defaultStates
    var rightFingerStates: [FingerInfo] = FingerInfo.defaultStates
}

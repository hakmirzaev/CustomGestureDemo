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
    var curlRatio: Float
    var isPinching: Bool
    var isExtended: Bool
    var isCurled: Bool

    static let defaultStates: [FingerInfo] = [
        FingerInfo(id: "thumb", name: "Thumb", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "index", name: "Index", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "middle", name: "Middle", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "ring", name: "Ring", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "little", name: "Little", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
    ]
}

// MARK: - App Model

@Observable
@MainActor
class AppModel {
    // MARK: Settings

    var immersiveSpaceIsShown = false
    var showJointSpheres = true

    // MARK: Active Gestures

    var leftSpiderGesture = false
    var rightSpiderGesture = false
    var leftPeaceGesture = false
    var rightPeaceGesture = false

    var isSpiderGestureActive: Bool { leftSpiderGesture || rightSpiderGesture }
    var isPeaceGestureActive: Bool { leftPeaceGesture || rightPeaceGesture }

    // MARK: Finger States

    var leftFingerStates: [FingerInfo] = FingerInfo.defaultStates
    var rightFingerStates: [FingerInfo] = FingerInfo.defaultStates
}

/*
 Bone.swift
 CustomGestureDemo

 An enumeration that represents each bone segment within a finger
 of the hand skeleton.
*/

/// Identifies a bone segment within a finger of the hand skeleton.
enum Bone: Int, CaseIterable, Sendable {
    case arm
    case wrist
    case metacarpal
    case knuckle
    case intermediateBase
    case intermediateTip
    case tip
}

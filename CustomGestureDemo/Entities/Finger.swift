/*
 Finger.swift
 CustomGestureDemo

 An enumeration representing each finger that forms the hand's skeleton.
*/

/// Identifies a finger (or structural group) on a hand.
enum Finger: Int, CaseIterable, Sendable {
    case forearm
    case thumb
    case index
    case middle
    case ring
    case little
}

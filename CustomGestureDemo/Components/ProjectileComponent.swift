/*
 ProjectileComponent.swift
 CustomGestureDemo

 A component that tracks a launched projectile entity through its parabolic trajectory.
*/

import RealityKit
import simd

/// Marks an entity as a launched projectile with physics parameters.
/// The ``GestureVisualizationSystem`` updates projectile positions every frame
/// using a parabolic trajectory: position = initial + velocity×t + ½g×t².
struct ProjectileComponent: Component {
    /// The initial velocity of the projectile in world space (m/s).
    var velocity: SIMD3<Float>

    /// The world-space position at launch time.
    var initialPosition: SIMD3<Float>

    /// The time the projectile was launched (`CACurrentMediaTime`).
    var startTime: Double

    /// How long the projectile lives before being removed (seconds).
    var lifetime: Double = 3.0
}

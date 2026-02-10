/*
 GestureVisualizationSystem.swift
 CustomGestureDemo

 A system that detects custom hand gestures and manages visual feedback.

 This system runs every frame and:
 1. Detects gestures (spider web, peace sign) on both hands
 2. Spawns/removes visualization entities (colored spheres above the wrist)
 3. Tracks wrist velocity for throw detection
 4. Manages launched projectile trajectories
 5. Updates the AppModel with gesture states, finger curl ratios, and pinch states
 6. Plays spatial feedback sounds on gesture activation and throw
*/

import RealityKit
import ARKit
import QuartzCore
import simd
import SwiftUI

/// A system that detects custom hand gestures and shows/hides visualization entities.
struct GestureVisualizationSystem: System {

    // MARK: - Queries

    static let handQuery = EntityQuery(where: .has(HandTrackingComponent.self))
    static let projectileQuery = EntityQuery(where: .has(ProjectileComponent.self))

    // MARK: - App Model Bridge

    nonisolated(unsafe) static var appModel: AppModel?

    // MARK: - Previous Gesture State (for sound triggering)

    nonisolated(unsafe) static var prevLeftSpider = false
    nonisolated(unsafe) static var prevRightSpider = false
    nonisolated(unsafe) static var prevLeftPeace = false
    nonisolated(unsafe) static var prevRightPeace = false

    // MARK: - Initialization

    init(scene: RealityKit.Scene) {}

    // MARK: - System Update

    func update(context: SceneUpdateContext) {
        updateGestures(context: context)
        updateProjectiles(context: context)
    }

    // MARK: - Gesture Detection & Visualization

    private func updateGestures(context: SceneUpdateContext) {
        let handEntities = context.entities(matching: Self.handQuery, updatingSystemWhen: .rendering)
        let currentTime = CACurrentMediaTime()

        for entity in handEntities {
            guard let handComp = entity.components[HandTrackingComponent.self] else { continue }
            let isLeft = handComp.chirality == .left

            let anchor: HandAnchor? = isLeft
                ? HandTrackingSystem.latestLeftHand
                : HandTrackingSystem.latestRightHand

            guard let handAnchor = anchor, let skeleton = handAnchor.handSkeleton else {
                clearVisualizations(from: entity)
                updateGestureStates(isLeft: isLeft, spider: false, peace: false)
                continue
            }

            // --- Detect gestures ---
            let isSpider = SpiderGestureDetector.detect(handSkeleton: skeleton)
            let isPeace = PeaceGestureDetector.detect(handSkeleton: skeleton)

            // --- Sound feedback on first activation ---
            let prevSpider = isLeft ? Self.prevLeftSpider : Self.prevRightSpider
            let prevPeace = isLeft ? Self.prevLeftPeace : Self.prevRightPeace

            if isSpider && !prevSpider {
                SoundManager.shared.playGestureDetected()
            }
            if isPeace && !prevPeace {
                SoundManager.shared.playGestureDetected()
            }

            if isLeft {
                Self.prevLeftSpider = isSpider
                Self.prevLeftPeace = isPeace
            } else {
                Self.prevRightSpider = isSpider
                Self.prevRightPeace = isPeace
            }

            // --- Update app model ---
            updateGestureStates(isLeft: isLeft, spider: isSpider, peace: isPeace)
            updateFingerStates(skeleton: skeleton, handAnchor: handAnchor, isLeft: isLeft)

            // --- Spider gesture: red energy sphere + throw ---
            if isSpider {
                addOrUpdateSphere(
                    on: entity, named: SpiderGestureDetector.entityName,
                    color: .red, radius: 0.03,
                    handAnchor: handAnchor, skeleton: skeleton
                )

                let wristPos = HandPoseUtilities.worldPosition(
                    of: .wrist, handAnchor: handAnchor, skeleton: skeleton
                )
                ThrowDetector.addSample(position: wristPos, time: currentTime, isLeft: isLeft)

                let throwResult = ThrowDetector.detectThrow(isLeft: isLeft, currentTime: currentTime)
                if throwResult.isThrow {
                    launchProjectile(
                        from: entity, named: SpiderGestureDetector.entityName,
                        velocity: throwResult.velocity, color: .cyan
                    )
                    SoundManager.shared.playThrow()
                }
            } else {
                removeVisualization(from: entity, named: SpiderGestureDetector.entityName)
                ThrowDetector.reset(isLeft: isLeft)
            }

            // --- Peace gesture: green sphere ---
            if isPeace {
                addOrUpdateSphere(
                    on: entity, named: PeaceGestureDetector.entityName,
                    color: .green, radius: 0.025,
                    handAnchor: handAnchor, skeleton: skeleton
                )
            } else {
                removeVisualization(from: entity, named: PeaceGestureDetector.entityName)
            }
        }
    }

    // MARK: - Sphere Visualization

    private func addOrUpdateSphere(
        on handEntity: Entity,
        named name: String,
        color: UIColor,
        radius: Float,
        handAnchor: HandAnchor,
        skeleton: HandSkeleton
    ) {
        let existing = handEntity.findEntity(named: name)
        let sphere: ModelEntity

        if let s = existing as? ModelEntity {
            sphere = s
        } else {
            sphere = ModelEntity(
                mesh: .generateSphere(radius: radius),
                materials: [SimpleMaterial(color: color, isMetallic: true)]
            )
            sphere.name = name
            handEntity.addChild(sphere)
        }

        // Position above the wrist using the wrist joint and its "up" (palm normal) direction.
        let wristJoint = skeleton.joint(.wrist)
        let originFromWrist = handAnchor.originFromAnchorTransform * wristJoint.anchorFromJointTransform

        let wristPos = SIMD3<Float>(
            originFromWrist.columns.3.x,
            originFromWrist.columns.3.y,
            originFromWrist.columns.3.z
        )
        // The Y-axis of the wrist joint transform points away from the palm.
        let palmNormal = simd_normalize(SIMD3<Float>(
            originFromWrist.columns.1.x,
            originFromWrist.columns.1.y,
            originFromWrist.columns.1.z
        ))

        // Offset 6 cm above the wrist along the palm normal.
        sphere.setPosition(wristPos + palmNormal * 0.06, relativeTo: nil)
    }

    private func removeVisualization(from entity: Entity, named name: String) {
        guard let child = entity.findEntity(named: name) else { return }
        child.removeFromParent()
    }

    private func clearVisualizations(from entity: Entity) {
        removeVisualization(from: entity, named: SpiderGestureDetector.entityName)
        removeVisualization(from: entity, named: PeaceGestureDetector.entityName)
    }

    // MARK: - Projectile Launch

    private func launchProjectile(
        from handEntity: Entity,
        named name: String,
        velocity: SIMD3<Float>,
        color: UIColor
    ) {
        guard let existing = handEntity.findEntity(named: name) else { return }
        let worldPos = existing.position(relativeTo: nil)
        existing.removeFromParent()

        let projectile = ModelEntity(
            mesh: .generateSphere(radius: 0.03),
            materials: [SimpleMaterial(color: color, isMetallic: true)]
        )
        projectile.position = worldPos
        projectile.components.set(ProjectileComponent(
            velocity: velocity * 2.0,
            initialPosition: worldPos,
            startTime: CACurrentMediaTime()
        ))

        if let root = handEntity.parent {
            root.addChild(projectile)
        }
    }

    // MARK: - Projectile Physics

    private func updateProjectiles(context: SceneUpdateContext) {
        let projectiles = context.entities(matching: Self.projectileQuery, updatingSystemWhen: .rendering)
        let currentTime = CACurrentMediaTime()

        for entity in projectiles {
            guard let comp = entity.components[ProjectileComponent.self] else { continue }
            let elapsed = Float(currentTime - comp.startTime)

            if elapsed > Float(comp.lifetime) {
                entity.removeFromParent()
                continue
            }

            let gravity = SIMD3<Float>(0, -4.0, 0)
            let position = comp.initialPosition
                + comp.velocity * elapsed
                + 0.5 * gravity * elapsed * elapsed
            entity.position = position

            let lifeFraction = elapsed / Float(comp.lifetime)
            let scale = max(0.1, 1.0 - lifeFraction * 0.8)
            entity.scale = SIMD3<Float>(repeating: scale)
        }
    }

    // MARK: - App Model Updates

    private func updateGestureStates(isLeft: Bool, spider: Bool, peace: Bool) {
        guard let model = Self.appModel else { return }
        if isLeft {
            model.leftSpiderGesture = spider
            model.leftPeaceGesture = peace
        } else {
            model.rightSpiderGesture = spider
            model.rightPeaceGesture = peace
        }
    }

    private func updateFingerStates(skeleton: HandSkeleton, handAnchor: HandAnchor, isLeft: Bool) {
        guard let model = Self.appModel else { return }

        // Thumb uses palm-relative method.
        let thumbRatio = HandPoseUtilities.thumbCurlRatio(skeleton: skeleton)
        let thumbCurled = thumbRatio < 0.75
        let thumbExtended = thumbRatio > 0.95

        // Other fingers use standard distance-ratio method.
        let fingerDefs: [(id: String, name: String, tip: HandSkeleton.JointName, knuckle: HandSkeleton.JointName)] = [
            ("index",  "Index",  .indexFingerTip,   .indexFingerKnuckle),
            ("middle", "Middle", .middleFingerTip,  .middleFingerKnuckle),
            ("ring",   "Ring",   .ringFingerTip,    .ringFingerKnuckle),
            ("little", "Little", .littleFingerTip,  .littleFingerKnuckle)
        ]

        var states: [FingerInfo] = []

        // Thumb entry
        states.append(FingerInfo(
            id: "thumb",
            name: "Thumb",
            curlRatio: thumbRatio,
            isPinching: false, // Thumb doesn't pinch with itself
            isExtended: thumbExtended,
            isCurled: thumbCurled
        ))

        // Other fingers
        for finger in fingerDefs {
            let ratio = HandPoseUtilities.curlRatio(
                skeleton: skeleton, tip: finger.tip, knuckle: finger.knuckle
            )
            let pinching = HandPoseUtilities.isPinching(
                skeleton: skeleton, fingerTip: finger.tip
            )

            // Play pinch sound on first detection.
            if pinching {
                let prevStates = isLeft ? model.leftFingerStates : model.rightFingerStates
                if let prevFinger = prevStates.first(where: { $0.id == finger.id }),
                   !prevFinger.isPinching {
                    SoundManager.shared.playPinch()
                }
            }

            states.append(FingerInfo(
                id: finger.id,
                name: finger.name,
                curlRatio: ratio,
                isPinching: pinching,
                isExtended: ratio > 1.15,
                isCurled: ratio < 1.05
            ))
        }

        if isLeft {
            model.leftFingerStates = states
        } else {
            model.rightFingerStates = states
        }
    }
}

/*
 GestureVisualizationSystem.swift
 CustomGestureDemo

 A system that detects custom hand gestures and manages visual feedback.
*/

import RealityKit
import ARKit
import QuartzCore
import simd
import SwiftUI

struct GestureVisualizationSystem: System {

    // MARK: - Queries

    static let handQuery = EntityQuery(where: .has(HandTrackingComponent.self))
    static let projectileQuery = EntityQuery(where: .has(ProjectileComponent.self))

    // MARK: - Bridges

    nonisolated(unsafe) static var appModel: AppModel?

    /// Pre-loaded sphere.usdz model template. Set by HandTrackingView on appear.
    nonisolated(unsafe) static var sphereTemplate: Entity?

    // MARK: - Previous State (for sound — only fire once per gesture activation per hand)

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

            // --- Detect gestures using math-based detectors ---
            let isSpider = SpiderGestureDetector.detect(handSkeleton: skeleton)
            let isPeace = PeaceGestureDetector.detect(handSkeleton: skeleton)

            // --- Sound: only on first activation per hand ---
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
            updateFingerStates(skeleton: skeleton, isLeft: isLeft)

            // --- Spider gesture: sphere + throw ---
            if isSpider {
                addOrUpdateSphere(
                    on: entity, named: SpiderGestureDetector.entityName,
                    color: .red,
                    handAnchor: handAnchor, skeleton: skeleton,
                    isLeft: isLeft
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

            // --- Peace gesture: detection only, no sphere ---
        }
    }

    // MARK: - Sphere Visualization (using sphere.usdz or generated fallback)

    private func addOrUpdateSphere(
        on handEntity: Entity,
        named name: String,
        color: UIColor,
        handAnchor: HandAnchor,
        skeleton: HandSkeleton,
        isLeft: Bool
    ) {
        let existing = handEntity.findEntity(named: name)
        let sphere: Entity

        if let s = existing {
            sphere = s
        } else if let template = Self.sphereTemplate {
            // Use the uploaded sphere.usdz model.
            sphere = template.clone(recursive: true)
            sphere.name = name
            sphere.scale = SIMD3<Float>(repeating: 0.5)
            handEntity.addChild(sphere)
        } else {
            // Fallback: generated sphere if model not loaded yet.
            let model = ModelEntity(
                mesh: .generateSphere(radius: 0.03),
                materials: [SimpleMaterial(color: color, isMetallic: true)]
            )
            model.name = name
            handEntity.addChild(model)
            sphere = model
        }

        // --- Position: midpoint between joint 25 (forearmWrist) and joint 10 (middleFingerMetacarpal),
        //     offset toward the INSIDE of the palm using a cross-product palm normal.
        //
        //     The cross product of (wrist→indexKnuckle) × (wrist→littleKnuckle) gives:
        //       • For RIGHT hand: points toward the palm (inward)
        //       • For LEFT hand:  points away from the palm (dorsal)
        //     So we negate it for the left hand to get a consistent palm-inward direction. ---

        let pos25 = HandPoseUtilities.worldPosition(of: .forearmWrist, handAnchor: handAnchor, skeleton: skeleton)
        let pos10 = HandPoseUtilities.worldPosition(of: .middleFingerMetacarpal, handAnchor: handAnchor, skeleton: skeleton)
        let midpoint = (pos25 + pos10) / 2.0

        // Compute the palm normal from actual joint geometry (robust for both hands).
        let wristPos = HandPoseUtilities.worldPosition(of: .wrist, handAnchor: handAnchor, skeleton: skeleton)
        let indexKnucklePos = HandPoseUtilities.worldPosition(of: .indexFingerKnuckle, handAnchor: handAnchor, skeleton: skeleton)
        let littleKnucklePos = HandPoseUtilities.worldPosition(of: .littleFingerKnuckle, handAnchor: handAnchor, skeleton: skeleton)

        let toIndex = indexKnucklePos - wristPos
        let toLittle = littleKnucklePos - wristPos
        var palmInward = simd_normalize(simd_cross(toIndex, toLittle))

        // Flip for left hand (cross product direction is mirrored).
        if isLeft {
            palmInward = -palmInward
        }

        // Offset 6 cm inward so the sphere floats clearly in front of the palm.
        let position = midpoint + palmInward * 0.1

        sphere.setPosition(position, relativeTo: nil)
    }

    private func removeVisualization(from entity: Entity, named name: String) {
        guard let child = entity.findEntity(named: name) else { return }
        child.removeFromParent()
    }

    private func clearVisualizations(from entity: Entity) {
        removeVisualization(from: entity, named: SpiderGestureDetector.entityName)
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

        let projectile: Entity
        if let template = Self.sphereTemplate {
            projectile = template.clone(recursive: true)
            projectile.scale = SIMD3<Float>(repeating: 0.5)
        } else {
            projectile = ModelEntity(
                mesh: .generateSphere(radius: 0.03),
                materials: [SimpleMaterial(color: color, isMetallic: true)]
            )
        }
        projectile.position = worldPos
        projectile.components.set(ProjectileComponent(
            velocity: velocity * 1.2,
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
            entity.scale = SIMD3<Float>(repeating: 0.5 * scale)
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

    /// Updates finger states — NO sound here, just state updates.
    private func updateFingerStates(skeleton: HandSkeleton, isLeft: Bool) {
        guard let model = Self.appModel else { return }

        let thumbRatio = HandPoseUtilities.thumbCurlRatio(skeleton: skeleton)

        let fingerDefs: [(id: String, name: String, tip: HandSkeleton.JointName, knuckle: HandSkeleton.JointName)] = [
            ("index",  "Index",  .indexFingerTip,   .indexFingerKnuckle),
            ("middle", "Middle", .middleFingerTip,  .middleFingerKnuckle),
            ("ring",   "Ring",   .ringFingerTip,    .ringFingerKnuckle),
            ("little", "Little", .littleFingerTip,  .littleFingerKnuckle)
        ]

        var states: [FingerInfo] = []

        states.append(FingerInfo(
            id: "thumb", name: "Thumb",
            curlRatio: thumbRatio,
            isPinching: false,
            isExtended: thumbRatio > 0.85,
            isCurled: thumbRatio < 0.75
        ))

        for finger in fingerDefs {
            let ratio = HandPoseUtilities.curlRatio(
                skeleton: skeleton, tip: finger.tip, knuckle: finger.knuckle
            )
            let pinching = HandPoseUtilities.isPinching(
                skeleton: skeleton, fingerTip: finger.tip
            )

            states.append(FingerInfo(
                id: finger.id, name: finger.name,
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

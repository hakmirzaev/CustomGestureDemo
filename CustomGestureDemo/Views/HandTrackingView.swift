/*
 HandTrackingView.swift
 CustomGestureDemo

 The immersive space view that creates and displays hand-tracking entities
 and the gesture visualization manager.
*/

import SwiftUI
import RealityKit
import ARKit

/// A reality view that contains hand-tracking entities and gesture visualization.
///
/// This view creates left and right hand entities with ``HandTrackingComponent``
/// instances, plus a gesture manager entity with ``GestureVisualizationComponent``.
/// The corresponding systems handle all tracking and visualization automatically.
struct HandTrackingView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        RealityView { content in
            makeHandEntities(in: content)
            makeGestureManager(in: content)
        }
        .onAppear {
            // Bridge the app model to the gesture system for UI updates.
            GestureVisualizationSystem.appModel = appModel

            // Sync the initial joint sphere visibility setting.
            HandTrackingSystem.showJointSpheres = appModel.showJointSpheres
        }
        .onChange(of: appModel.showJointSpheres) { _, newValue in
            HandTrackingSystem.showJointSpheres = newValue
        }
    }

    // MARK: - Entity Setup

    /// Creates left and right hand entities with hand-tracking components.
    @MainActor
    private func makeHandEntities(in content: any RealityViewContentProtocol) {
        // Add the left hand.
        let leftHand = Entity()
        leftHand.components.set(HandTrackingComponent(chirality: .left))
        content.add(leftHand)

        // Add the right hand.
        let rightHand = Entity()
        rightHand.components.set(HandTrackingComponent(chirality: .right))
        content.add(rightHand)
    }

    /// Creates a gesture manager entity that activates the gesture visualization system.
    @MainActor
    private func makeGestureManager(in content: any RealityViewContentProtocol) {
        let gestureManager = Entity()
        gestureManager.components.set(GestureVisualizationComponent())
        content.add(gestureManager)
    }
}

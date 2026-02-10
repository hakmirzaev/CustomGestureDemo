/*
 GestureVisualizationComponent.swift
 CustomGestureDemo

 A component that marks an entity as the gesture visualization manager.
*/

import RealityKit

/// Marks an entity as the gesture visualization manager.
/// The corresponding ``GestureVisualizationSystem`` uses hand anchors to detect
/// custom gestures and manage visual feedback entities in the scene.
struct GestureVisualizationComponent: Component {
    init() {
        GestureVisualizationSystem.registerSystem()
    }
}

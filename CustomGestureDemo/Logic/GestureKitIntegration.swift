/*
 GestureKitIntegration.swift
 CustomGestureDemo

 Integration guide for using GestureKit to detect custom gestures.

 GestureKit (https://github.com/nthState/GestureKit) provides a visual workflow
 for creating custom gestures without writing detection math manually.

 ┌─────────────────────────────────────────────────────────────────────────┐
 │                    THREE APPROACHES TO CUSTOM GESTURES                  │
 ├─────────────────────────────────────────────────────────────────────────┤
 │                                                                         │
 │  1. PROCEDURAL / MATH-BASED (this project: SpiderGestureDetector)      │
 │     • Lowest latency, no ML overhead                                    │
 │     • Compare joint distances/angles each frame                         │
 │     • Best for: simple poses defined by finger curl/extend states       │
 │                                                                         │
 │  2. GESTUREKIT / COMPOSER-BASED (shown below)                           │
 │     • Visual gesture recording via Gesture Composer app                 │
 │     • Exports .gesturecomposer packages                                 │
 │     • Supports multi-step gestures and USDZ animations                  │
 │     • Best for: complex/dynamic gestures, rapid prototyping             │
 │                                                                         │
 │  3. CREATE ML / ML-BASED (not shown)                                    │
 │     • Train Hand Pose / Hand Action classifiers                         │
 │     • 50+ images per class for pose, video clips for action             │
 │     • Best for: shape-based poses (heart, OK sign) and actions (wave)   │
 │                                                                         │
 └─────────────────────────────────────────────────────────────────────────┘

 HOW TO ADD GESTUREKIT:

 1. In Xcode: File → Add Package Dependencies
 2. Enter URL: https://github.com/nthState/GestureKit
 3. Add to your app target
 4. Download Gesture Composer from the visionOS App Store
 5. Record your peace sign gesture and export the .gesturecomposer package
 6. Add the package to your Xcode project resources
 7. Uncomment the code below

 NOTE: The code below is commented out because it requires:
   - GestureKit package added as a dependency
   - A .gesturecomposer file for the peace sign gesture
*/

// MARK: - GestureKit Example Code (uncomment after adding the package)

/*
import GestureKit
import RealityKit
import SwiftUI

/// Example: Using GestureKit for peace sign detection.
///
/// GestureKit replaces manual math with recorded gesture packages.
/// The GestureDetector continuously monitors hand tracking data
/// and emits detected gestures through an AsyncSequence.
struct GestureKitPeaceView: View {

    // MARK: - Configuration

    /// Point this to your exported .gesturecomposer file.
    let configuration = GestureDetectorConfiguration(packages: [
        Bundle.main.url(forResource: "PeaceSign", withExtension: "gesturecomposer")!
    ])

    let detector: GestureDetector

    init() {
        detector = GestureDetector(configuration: configuration)
    }

    // MARK: - View

    var body: some View {
        RealityView { _ in }
            .task {
                // Listen for gesture detections from GestureKit.
                for await gesture in detector.detectedGestures {
                    print("GestureKit detected: \(gesture.description)")

                    // Handle the peace sign gesture.
                    // gesture.description will match the name you set in Gesture Composer.
                }
            }
    }
}

/// Example: Using GestureKit's VirtualHands for hand visualization.
///
/// VirtualHands provides an alternative to our manual sphere approach.
/// It supports joints, bones, and full 3D hand models with customizable colors.
struct GestureKitHandVisualization {

    let virtualHands: VirtualHands

    init() {
        let config = VirtualHandsConfiguration(
            left: HandConfiguration(
                color: .blue,
                usdz: HandConfiguration.defaultModel(chirality: .left)
            ),
            right: HandConfiguration(
                color: .red,
                usdz: HandConfiguration.defaultModel(chirality: .right)
            ),
            handRenderOptions: [.model, .joints, .bones]
        )
        virtualHands = VirtualHands(configuration: config)
    }

    /// Call this to create hand entities in a RealityView.
    func createHands() throws -> (Entity, Entity) {
        return try virtualHands.createVirtualHands()
    }

    /// Start these as concurrent tasks in your view.
    func startTracking() async {
        await virtualHands.startSession()
        // Also call: await virtualHands.startHandTracking()
        // Also call: await virtualHands.handleSessionEvents()
    }
}
*/

/*
 CustomGestureDemoApp.swift
 CustomGestureDemo

 The app's main entry point.
*/

import SwiftUI

@main
struct CustomGestureDemoApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        // Main control window.
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .defaultSize(width: 620, height: 780)

        // Settings window (opened on demand).
        WindowGroup(id: "Settings") {
            SettingsView()
                .environment(appModel)
        }
        .defaultSize(width: 420, height: 380)

        // Immersive space for hand tracking and gesture visualization.
        ImmersiveSpace(id: "HandTracking") {
            HandTrackingView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}

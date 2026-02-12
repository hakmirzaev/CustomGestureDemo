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
        .defaultSize(width: 550, height: 710)

        // Settings window (opened on demand, placed beside the main window).
        WindowGroup(id: "Settings") {
            SettingsView()
                .environment(appModel)
        }
        .defaultSize(width: 460, height: 650)
        .defaultWindowPlacement { content, context in
            // Place the settings window to the right of the main window.
            if let mainWindow = context.windows.first {
                return WindowPlacement(.trailing(mainWindow))
            }
            return WindowPlacement()
        }

        // Immersive space for hand tracking and gesture visualization.
        ImmersiveSpace(id: "HandTracking") {
            HandTrackingView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}

/*
 SettingsView.swift
 CustomGestureDemo

 A settings window for configuring hand tracking visualization options.
*/

import SwiftUI

/// A settings window that lets the user configure hand tracking visualization.
struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack {
            Form {
                Section("Hand Tracking") {
                    Toggle("Show Joint Spheres", isOn: $appModel.showJointSpheres)
                }

                Section {
                    Text("When enabled, white spheres appear on each of the 27 hand skeleton joints tracked by ARKit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    Label("Spider Gesture", systemImage: "hand.raised.fingers.spread")
                    Text("Extend index + little fingers, curl middle + ring + thumb. Flick wrist to throw.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("Peace Gesture", systemImage: "hand.raised")
                    Text("Extend index + middle fingers with a V-shape, curl ring + little + thumb.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .frame(minWidth: 350, minHeight: 300)
    }
}

#Preview(windowStyle: .automatic) {
    SettingsView()
        .environment(AppModel())
}

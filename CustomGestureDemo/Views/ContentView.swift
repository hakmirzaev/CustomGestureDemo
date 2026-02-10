/*
 ContentView.swift
 CustomGestureDemo

 The main window view with gesture status indicators, dynamic gesture icon,
 immersive space controls, and real-time hand finger status.
*/

import SwiftUI

/// The main window view.
struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // --- Top: Gesture Status Indicators ---
            GestureStatusView()
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Spacer()

            // --- Center: App Controls ---
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 6) {
                    Text("Custom Gesture Demo")
                        .font(.extraLargeTitle)

                    Text("Hand tracking & custom gestures for visionOS")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Dynamic gesture icon area
                gestureIconArea
                    .frame(height: 100)

                Text(statusMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        Task { await toggleImmersiveSpace() }
                    } label: {
                        Label(
                            appModel.immersiveSpaceIsShown
                                ? "Exit Immersive Space"
                                : "Enter Immersive Space",
                            systemImage: appModel.immersiveSpaceIsShown
                                ? "xmark.circle" : "visionpro"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appModel.immersiveSpaceIsShown ? .red : .blue)

                    Button {
                        openWindow(id: "Settings")
                    } label: {
                        Label("Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: 300)
            }

            Spacer()

            // --- Bottom: Hand Finger Status ---
            if appModel.immersiveSpaceIsShown {
                HandStatusView()
                    .padding(.bottom, 20)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appModel.immersiveSpaceIsShown)
        .animation(.easeInOut(duration: 0.2), value: appModel.isSpiderGestureActive)
        .animation(.easeInOut(duration: 0.2), value: appModel.isPeaceGestureActive)
    }

    // MARK: - Dynamic Gesture Icon

    /// Shows the active gesture icon or the default hand icon.
    /// Left side = left hand gesture, right side = right hand gesture.
    @ViewBuilder
    private var gestureIconArea: some View {
        HStack(spacing: 40) {
            // Left hand
            gestureIcon(
                spider: appModel.leftSpiderGesture,
                peace: appModel.leftPeaceGesture,
                label: "L"
            )

            // Right hand
            gestureIcon(
                spider: appModel.rightSpiderGesture,
                peace: appModel.rightPeaceGesture,
                label: "R"
            )
        }
    }

    @ViewBuilder
    private func gestureIcon(spider: Bool, peace: Bool, label: String) -> some View {
        VStack(spacing: 4) {
            if spider {
                Text("🤘")
                    .font(.system(size: 50))
                    .transition(.scale.combined(with: .opacity))
            } else if peace {
                Text("✌️")
                    .font(.system(size: 50))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "hand.raised.fingers.spread")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, options: .repeating,
                                  isActive: appModel.immersiveSpaceIsShown)
                    .transition(.scale.combined(with: .opacity))
            }

            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Status Message

    private var statusMessage: String {
        if !appModel.immersiveSpaceIsShown {
            return "Enter the immersive space to start hand tracking"
        }
        if appModel.isSpiderGestureActive && appModel.isPeaceGestureActive {
            return "🤘 Spider + ✌️ Peace detected! Flick wrist to throw."
        }
        if appModel.isSpiderGestureActive {
            return "🤘 Spider gesture detected! Flick your wrist to throw."
        }
        if appModel.isPeaceGestureActive {
            return "✌️ Peace sign detected!"
        }
        return "Hand tracking is active — try the gestures!"
    }

    // MARK: - Immersive Space Control

    private func toggleImmersiveSpace() async {
        if appModel.immersiveSpaceIsShown {
            await dismissImmersiveSpace()
            appModel.immersiveSpaceIsShown = false
        } else {
            let result = await openImmersiveSpace(id: "HandTracking")
            switch result {
            case .opened:
                appModel.immersiveSpaceIsShown = true
            case .error, .userCancelled:
                appModel.immersiveSpaceIsShown = false
            @unknown default:
                appModel.immersiveSpaceIsShown = false
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}

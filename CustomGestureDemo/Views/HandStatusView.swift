/*
 HandStatusView.swift
 CustomGestureDemo

 Displays real-time finger status for both hands:
   • Extended / Curled label with color coding
   • Curl ratio numeric value with info explanation
   • Pinch checkmark when thumb touches a fingertip
*/

import SwiftUI

/// A panel showing finger states for both hands side by side.
struct HandStatusView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 8) {
            Text("Hand Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 16) {
                // Left hand
                HandFingerColumn(
                    title: "Left Hand",
                    emoji: "🫲",
                    fingers: appModel.leftFingerStates
                )

                Divider()
                    .frame(height: 140)

                // Right hand
                HandFingerColumn(
                    title: "Right Hand",
                    emoji: "🫱",
                    fingers: appModel.rightFingerStates
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Hand Column

private struct HandFingerColumn: View {
    let title: String
    let emoji: String
    let fingers: [FingerInfo]

    @State private var showRatioInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(emoji) \(title)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)

            // Header row
            HStack(spacing: 0) {
                Text("Finger")
                    .frame(width: 48, alignment: .leading)

                Text("State")
                    .frame(width: 60, alignment: .center)

                // Ratio header with info button
                HStack(spacing: 2) {
                    Text("Ratio")
                    Button {
                        showRatioInfo.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 8))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showRatioInfo) {
                        RatioInfoView()
                    }
                }
                .frame(width: 46, alignment: .trailing)

                Text("Pinch")
                    .frame(width: 36, alignment: .center)
            }
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
            .foregroundStyle(.tertiary)

            ForEach(fingers) { finger in
                FingerRow(finger: finger)
            }
        }
        .frame(minWidth: 190)
    }
}

// MARK: - Ratio Info Popover

private struct RatioInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Curl Ratio Explained")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Thumb")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Distance from **thumb tip** to **palm center** (middle finger knuckle), divided by hand size (**wrist** to **palm center**).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("< 0.75 = Curled  •  > 0.95 = Extended")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                } icon: {
                    Image(systemName: "hand.thumbsup")
                        .foregroundStyle(.orange)
                }

                Divider()

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Other Fingers")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Distance from **fingertip** to **wrist**, divided by distance from **knuckle** to **wrist**.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("< 1.10 = Curled  •  > 1.15 = Extended")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                } icon: {
                    Image(systemName: "hand.raised.fingers.spread")
                        .foregroundStyle(.teal)
                }
            }
        }
        .padding()
        .frame(width: 320)
    }
}

// MARK: - Finger Row

private struct FingerRow: View {
    let finger: FingerInfo

    private var stateText: String {
        if finger.isExtended { return "Extended" }
        if finger.isCurled { return "Curled" }
        return "Neutral"
    }

    private var stateColor: Color {
        if finger.isExtended { return .green }
        if finger.isCurled { return .red }
        return .yellow
    }

    var body: some View {
        HStack(spacing: 0) {
            // Finger name
            Text(finger.name)
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 48, alignment: .leading)

            // Extended / Curled / Neutral
            Text(stateText)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(stateColor)
                .frame(width: 60, alignment: .center)

            // Curl ratio value
            Text(String(format: "%.2f", finger.curlRatio))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .trailing)

            // Pinch checkmark (not applicable for thumb itself)
            if finger.id == "thumb" {
                Text("—")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(width: 36, alignment: .center)
            } else {
                Text(finger.isPinching ? "✓" : "")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green)
                    .frame(width: 36, alignment: .center)
            }
        }
    }
}

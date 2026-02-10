/*
 GestureStatusView.swift
 CustomGestureDemo

 Displays active gesture indicators at the top of the main window.
*/

import SwiftUI

/// A horizontal bar that shows which custom gestures are currently active.
struct GestureStatusView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 24) {
            // Spider web gesture indicator (🤘 = horns / spider hand)
            GestureIndicator(
                emoji: "🤘",
                label: "Spider Web",
                leftActive: appModel.leftSpiderGesture,
                rightActive: appModel.rightSpiderGesture
            )

            Divider()
                .frame(height: 40)

            // Peace sign gesture indicator
            GestureIndicator(
                emoji: "✌️",
                label: "Peace Sign",
                leftActive: appModel.leftPeaceGesture,
                rightActive: appModel.rightPeaceGesture
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Gesture Indicator

private struct GestureIndicator: View {
    let emoji: String
    let label: String
    let leftActive: Bool
    let rightActive: Bool

    private var isActive: Bool { leftActive || rightActive }

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title)
                .opacity(isActive ? 1.0 : 0.3)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isActive)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    HandDot(label: "L", active: leftActive)
                    HandDot(label: "R", active: rightActive)
                }
            }
        }
    }
}

// MARK: - Hand Dot

private struct HandDot: View {
    let label: String
    let active: Bool

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(active ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

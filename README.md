# Custom Gesture Demo in VisionOS

A visionOS app that detects custom hand gestures using **ARKit Hand Tracking** and simple math — no machine learning required.

<!-- Add your screenshots to a screenshots/ folder -->
![Demo](screenshots/customGesture.gif)

## Overview

This project demonstrates how to build your own hand gesture vocabulary for Apple Vision Pro. It uses lightweight geometric calculations — joint distances, curl ratios, and wrist velocity — to recognize hand poses in real time.

Two custom gestures are implemented:

- **Spider-Man** 🤘 — Extend index + pinky, curl the rest. A 3D sphere appears on your palm. Flick your wrist to throw it with physics.
- **Peace Sign** ✌️ — Extend index + middle finger in a V-shape. Strict spread validation prevents false positives.

## Features

- **27-Joint Hand Visualization** — Toggle 3D spheres on every tracked joint
- **Projectile Physics** — Throw objects using natural wrist motion
- **Live Finger Dashboard** — See curl ratios, extension states, and pinch detection in real time
- **Spatial Audio Feedback** — Synthesized tones on gesture recognition
- **Fully Procedural** — All detection is math-based, transparent, and tunable

## Requirements

- Apple Vision Pro (or visionOS Simulator)
- Xcode 16.0+
- visionOS 2.0+

## Getting Started

1. Clone the repository
2. Open `CustomGestureDemo.xcodeproj` in Xcode
3. Run on Apple Vision Pro
4. Grant **Hand Tracking** permission when prompted
5. Tap **Enter Immersive Space** and try the gestures

## Project Structure

- **`Logic/`** — Gesture detection math: curl ratios, pinch, throw velocity
- **`Systems/`** — RealityKit ECS systems for tracking and visualization
- **`Views/`** — SwiftUI interface: dashboard, settings, gesture indicators
- **`Components/`** — RealityKit components for hands and projectiles
- **`Entities/`** — Hand joint mapping (27 joints → fingers → bones)

## How It Works

Instead of training ML models, gestures are detected by comparing joint positions each frame:

- **Finger state** = distance(fingertip → wrist) / distance(knuckle → wrist)
- **Thumb state** = distance(thumbTip → palmCenter) / handSize
- **Throw detection** = wrist velocity over recent frames

All thresholds are adjustable. The info button **(?)** in the Hand Status panel explains each measurement.

## License

MIT License — free to use and modify.

---

*Built with ARKit, RealityKit, and SwiftUI for Apple Vision Pro.*

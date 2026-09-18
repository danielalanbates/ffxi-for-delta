//
//  ControllerOverlayView.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI
import UIKit

public struct ControllerOverlayView: View {
    private let engine = VanaDielEngine.shared
    private let haptics = UIImpactFeedbackGenerator(style: .medium)

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            // Shoulder Triggers (L & R) tucked under the screen
            HStack {
                ShoulderButton(label: "L", buttonMask: VanaDielEngine.ControllerInput.l)
                Spacer()
                ShoulderButton(label: "R", buttonMask: VanaDielEngine.ControllerInput.r)
            }
            .padding(.horizontal, 28)

            // Main Lower Controller Area: D-Pad, Center Buttons, A/B
            HStack(alignment: .center, spacing: 0) {
                // Directional Pad (Left)
                DPadView()
                    .frame(width: 116, height: 116)

                Spacer(minLength: 8)

                // Center Menu Buttons (Select, Start)
                HStack(spacing: 12) {
                    PillButton(label: "SELECT", buttonMask: VanaDielEngine.ControllerInput.select)
                    PillButton(label: "START", buttonMask: VanaDielEngine.ControllerInput.start)
                }
                .padding(.top, 10)

                Spacer(minLength: 8)

                // Action Buttons (Right: B and A)
                ABButtonsView()
                    .frame(width: 116, height: 116)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .onAppear {
            haptics.prepare()
        }
    }
}

// Shoulder L/R button
struct ShoulderButton: View {
    let label: String
    let buttonMask: UInt16
    @State private var isPressed: Bool = false
    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .frame(width: 72, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isPressed ? Color.purple.opacity(0.7) : Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            haptics.impactOccurred()
                            VanaDielEngine.shared.setButtonState(button: buttonMask, isDown: true)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        VanaDielEngine.shared.setButtonState(button: buttonMask, isDown: false)
                    }
            )
    }
}

// Directional Pad with 8-way touch detection
struct DPadView: View {
    @State private var activeDirection: String? = nil
    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            // D-Pad Background Circle
            Circle()
                .fill(Color.black.opacity(0.45))
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))

            // Cross Vertical Bar
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.22))
                .frame(width: 36, height: 104)

            // Cross Horizontal Bar
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.22))
                .frame(width: 104, height: 36)

            // Direction Triangles
            VStack {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(activeDirection == "UP" ? .yellow : .white.opacity(0.7))
                    .padding(.top, 7)
                Spacer()
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(180))
                    .font(.system(size: 8))
                    .foregroundColor(activeDirection == "DOWN" ? .yellow : .white.opacity(0.7))
                    .padding(.bottom, 7)
            }
            HStack {
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(-90))
                    .font(.system(size: 8))
                    .foregroundColor(activeDirection == "LEFT" ? .yellow : .white.opacity(0.7))
                    .padding(.leading, 7)
                Spacer()
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 8))
                    .foregroundColor(activeDirection == "RIGHT" ? .yellow : .white.opacity(0.7))
                    .padding(.trailing, 7)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDPadTouch(location: value.location)
                }
                .onEnded { _ in
                    clearDPad()
                }
        )
    }

    private func handleDPadTouch(location: CGPoint) {
        let center = CGPoint(x: 58, y: 58)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let dist = hypot(dx, dy)

        if dist < 12 {
            clearDPad()
            return
        }

        let angle = atan2(dy, dx) * 180 / .pi
        let engine = VanaDielEngine.shared

        // Reset
        engine.setButtonState(button: VanaDielEngine.ControllerInput.up, isDown: false)
        engine.setButtonState(button: VanaDielEngine.ControllerInput.down, isDown: false)
        engine.setButtonState(button: VanaDielEngine.ControllerInput.left, isDown: false)
        engine.setButtonState(button: VanaDielEngine.ControllerInput.right, isDown: false)

        if angle >= -135 && angle <= -45 {
            activeDirection = "UP"
            engine.setButtonState(button: VanaDielEngine.ControllerInput.up, isDown: true)
        } else if angle >= 45 && angle <= 135 {
            activeDirection = "DOWN"
            engine.setButtonState(button: VanaDielEngine.ControllerInput.down, isDown: true)
        } else if angle > 135 || angle < -135 {
            activeDirection = "LEFT"
            engine.setButtonState(button: VanaDielEngine.ControllerInput.left, isDown: true)
        } else {
            activeDirection = "RIGHT"
            engine.setButtonState(button: VanaDielEngine.ControllerInput.right, isDown: true)
        }
    }

    private func clearDPad() {
        activeDirection = nil
        let engine = VanaDielEngine.shared
        engine.setButtonState(button: VanaDielEngine.ControllerInput.up, isDown: false)
        engine.setButtonState(button: VanaDielEngine.ControllerInput.down, isDown: false)
        engine.setButtonState(button: VanaDielEngine.ControllerInput.left, isDown: false)
        engine.setButtonState(button: VanaDielEngine.ControllerInput.right, isDown: false)
    }
}

// Action Buttons (A and B angled like GBA / Delta)
struct ABButtonsView: View {
    var body: some View {
        ZStack {
            // Button B (Lower Left)
            RoundActionButton(
                label: "B",
                color: Color(red: 0.82, green: 0.22, blue: 0.42),
                buttonMask: VanaDielEngine.ControllerInput.b
            )
            .offset(x: -22, y: 14)

            // Button A (Upper Right)
            RoundActionButton(
                label: "A",
                color: Color(red: 0.88, green: 0.28, blue: 0.48),
                buttonMask: VanaDielEngine.ControllerInput.a
            )
            .offset(x: 22, y: -14)
        }
    }
}

struct RoundActionButton: View {
    let label: String
    let color: Color
    let buttonMask: UInt16
    @State private var isPressed: Bool = false
    private let haptics = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        Circle()
            .fill(isPressed ? color.opacity(0.9) : color.opacity(0.65))
            .frame(width: 46, height: 46)
            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5))
            .overlay(
                Text(label)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            haptics.impactOccurred()
                            VanaDielEngine.shared.setButtonState(button: buttonMask, isDown: true)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        VanaDielEngine.shared.setButtonState(button: buttonMask, isDown: false)
                    }
            )
    }
}

struct PillButton: View {
    let label: String
    let buttonMask: UInt16
    @State private var isPressed: Bool = false
    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 3) {
            Capsule()
                .fill(isPressed ? Color.gray : Color.black.opacity(0.55))
                .frame(width: 32, height: 10)
                .rotationEffect(.degrees(-25))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        .rotationEffect(.degrees(-25))
                )
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.65))
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        haptics.impactOccurred()
                        VanaDielEngine.shared.setButtonState(button: buttonMask, isDown: true)
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    VanaDielEngine.shared.setButtonState(button: buttonMask, isDown: false)
                }
        )
    }
}

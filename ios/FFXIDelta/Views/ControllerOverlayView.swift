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
        VStack(spacing: 12) {
            // Shoulder Triggers (L & R)
            HStack {
                ShoulderButton(label: "L", buttonMask: VanaDielEngine.ControllerInput.l)
                Spacer()
                ShoulderButton(label: "R", buttonMask: VanaDielEngine.ControllerInput.r)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Main Lower Controller Area: D-Pad, Center Buttons, A/B
            HStack(alignment: .center) {
                // Directional Pad (Left)
                DPadView()
                    .frame(width: 150, height: 150)

                Spacer()

                // Center Menu Buttons (Select, Start)
                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        PillButton(label: "SELECT", buttonMask: VanaDielEngine.ControllerInput.select)
                        PillButton(label: "START", buttonMask: VanaDielEngine.ControllerInput.start)
                    }
                }
                .padding(.bottom, 20)

                Spacer()

                // Action Buttons (Right: B and A)
                ABButtonsView()
                    .frame(width: 150, height: 150)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
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
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .frame(width: 80, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isPressed ? Color.purple.opacity(0.6) : Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
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

// Directional Pad with 8-way drag gesture
struct DPadView: View {
    @State private var activeDirection: String? = nil
    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            // D-Pad Background Cross
            Circle()
                .fill(Color.black.opacity(0.4))
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

            // Cross Shapes
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.18))
                .frame(width: 44, height: 130)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.18))
                .frame(width: 130, height: 44)

            // Direction Indicators
            VStack {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(activeDirection == "UP" ? .yellow : .white.opacity(0.6))
                    .padding(.top, 10)
                Spacer()
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(180))
                    .font(.system(size: 10))
                    .foregroundColor(activeDirection == "DOWN" ? .yellow : .white.opacity(0.6))
                    .padding(.bottom, 10)
            }
            HStack {
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(-90))
                    .font(.system(size: 10))
                    .foregroundColor(activeDirection == "LEFT" ? .yellow : .white.opacity(0.6))
                    .padding(.leading, 10)
                Spacer()
                Image(systemName: "triangle.fill")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 10))
                    .foregroundColor(activeDirection == "RIGHT" ? .yellow : .white.opacity(0.6))
                    .padding(.trailing, 10)
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
        let center = CGPoint(x: 75, y: 75)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let dist = hypot(dx, dy)

        if dist < 15 {
            clearDPad()
            return
        }

        let angle = atan2(dy, dx) * 180 / .pi
        let engine = VanaDielEngine.shared

        // Reset directions
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
                color: Color(red: 0.8, green: 0.2, blue: 0.4),
                buttonMask: VanaDielEngine.ControllerInput.b
            )
            .offset(x: -28, y: 18)

            // Button A (Upper Right)
            RoundActionButton(
                label: "A",
                color: Color(red: 0.85, green: 0.3, blue: 0.5),
                buttonMask: VanaDielEngine.ControllerInput.a
            )
            .offset(x: 28, y: -18)
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
            .fill(isPressed ? color.opacity(0.8) : color.opacity(0.6))
            .frame(width: 54, height: 54)
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
            .overlay(
                Text(label)
                    .font(.system(size: 20, weight: .black, design: .rounded))
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
        VStack(spacing: 4) {
            Capsule()
                .fill(isPressed ? Color.gray : Color.black.opacity(0.5))
                .frame(width: 38, height: 12)
                .rotationEffect(.degrees(-25))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .rotationEffect(.degrees(-25))
                )
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
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

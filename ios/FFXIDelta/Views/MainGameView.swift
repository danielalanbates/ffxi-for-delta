//
//  MainGameView.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI

public struct MainGameView: View {
    @ObservedObject private var engine = VanaDielEngine.shared
    @ObservedObject private var controllerManager = GameControllerManager.shared
    @State private var showExportSheet: Bool = false
    @State private var showFeedbackSheet: Bool = false
    @State private var showSaveAlert: Bool = false

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dark styling
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.05, green: 0.07, blue: 0.12), Color(red: 0.02, green: 0.03, blue: 0.06)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Navigation / Quick Action Bar
                    HStack {
                        // Title / FPS
                        HStack(spacing: 6) {
                            Circle()
                                .fill(engine.currentFPS > 55 ? Color.green : Color.yellow)
                                .frame(width: 8, height: 8)
                            Text(String(format: "%.0f FPS", engine.currentFPS))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))

                            if controllerManager.hasPhysicalController {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 11))
                                    .foregroundColor(.purple)
                            }
                        }

                        Spacer()

                        // Action 1: Export ROM to Delta
                        Button(action: { showExportSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.forward.app.fill")
                                Text("Delta")
                                    .bold()
                            }
                            .font(.system(size: 12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        // Action 2: Battery Save Game
                        Button(action: {
                            engine.saveGameSRAM()
                            showSaveAlert = true
                        }) {
                            Image(systemName: "sdcard.fill")
                                .font(.system(size: 12))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        // Action 3: Playtest Feedback
                        Button(action: { showFeedbackSheet = true }) {
                            Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                                .font(.system(size: 12))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 8)

                    // Retro Bezel & Game Screen
                    VStack {
                        GameScreenView()
                            .frame(maxWidth: .infinity)
                            .frame(height: geometry.size.width * (160.0 / 240.0))
                            .background(Color.black)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1.5))
                            .padding(.horizontal, 8)
                    }

                    Spacer()

                    // Virtual Touch Gamepad
                    ControllerOverlayView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            DeltaExportView()
        }
        .sheet(isPresented: $showFeedbackSheet) {
            PlaytestFeedbackView()
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text("Saved to SRAM"),
                message: Text("Game state saved! You can export this battery save to Delta anytime."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            engine.startEngine()
        }
        .onDisappear {
            engine.stopEngine()
        }
    }
}

//
//  FFXIAdvanceMac.swift
//  FFXI Advance - macOS Desktop Player & Delta Tool
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI
import AppKit

@main
struct FFXIAdvanceMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacMainView()
                .frame(minWidth: 720, minHeight: 560)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct MacMainView: View {
    @State private var statusText: String = "Ready. Keyboard: Arrow Keys = D-Pad, Z = A Button, X = B Button, Enter = Start, Space = Select"
    @State private var currentZone: String = "Southern San d'Oria"
    @State private var playerLevel: Int = 1
    @State private var playerHP: Int = 50
    @State private var playerMaxHP: Int = 50
    @State private var playerTP: Int = 0
    @State private var inCombat: Bool = false
    @State private var logLines: [String] = [
        "Welcome to FINAL FANTASY XI Advance!",
        "Built for Delta for iOS by Bates LLC.",
        "Use Arrow keys + Z/X to explore."
    ]

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.10, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 12) {
                // Top Toolbar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FINAL FANTASY XI Advance")
                            .font(.headline.bold())
                            .foregroundColor(.yellow)
                        Text("Vana'diel for Delta iOS · Bates LLC (help@batesai.org)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: openROMInFinder) {
                        Label("Show ROM in Finder", systemImage: "folder")
                    }

                    Button(action: launchInMednafen) {
                        Label("Launch in Emulator", systemImage: "play.fill")
                    }

                    Button(action: copyTestFlightGuide) {
                        Label("TestFlight Guide", systemImage: "doc.text")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Virtual GBA Screen (240x160 scaled 3x to 720x480)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 2))

                    VStack(spacing: 0) {
                        // Environment area (60% height)
                        ZStack {
                            Color(red: 0.12, green: 0.28, blue: 0.14) // Forest green
                            VStack {
                                Text(currentZone)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.yellow)
                                    .padding(.top, 8)
                                Spacer()
                                HStack(spacing: 40) {
                                    // Moogle
                                    VStack(spacing: 2) {
                                        Text("Moogle")
                                            .font(.caption2.bold())
                                            .foregroundColor(.yellow)
                                        Circle().fill(Color.white).frame(width: 24, height: 24)
                                    }
                                    // Player
                                    VStack(spacing: 2) {
                                        Text("Daniel")
                                            .font(.caption2.bold())
                                            .foregroundColor(.cyan)
                                        RoundedRectangle(cornerRadius: 4).fill(Color.blue).frame(width: 28, height: 36)
                                    }
                                    // Rabbit / Mob
                                    VStack(spacing: 2) {
                                        Text("Wild Rabbit")
                                            .font(.caption2.bold())
                                            .foregroundColor(.orange)
                                        Circle().fill(Color.white.opacity(0.8)).frame(width: 20, height: 20)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .frame(height: 240)

                        // Bottom HUD & Battle Log
                        ZStack {
                            Color(red: 0.05, green: 0.08, blue: 0.16) // Blue marble window
                            HStack(alignment: .top, spacing: 16) {
                                // Stats
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Daniel Lv.\(playerLevel)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("HP: \(playerHP)/\(playerMaxHP)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("TP: \(playerTP)/3000")
                                        .font(.caption)
                                        .foregroundColor(playerTP >= 1000 ? .yellow : .blue)
                                }
                                .frame(width: 140)

                                Divider().background(Color.white.opacity(0.2))

                                // Log lines
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(logLines.suffix(3), id: \.self) { line in
                                        Text(line)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                        }
                        .frame(height: 120)
                    }
                }
                .frame(width: 600, height: 360)

                // Status Bar
                HStack {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("60.0 FPS · GBA Mode 3")
                        .font(.caption.monospaced())
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            setupKeyboardMonitor()
        }
    }

    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyPress(keyCode: event.keyCode)
            return event
        }
    }

    private func handleKeyPress(keyCode: UInt16) {
        switch keyCode {
        case 126: // Up Arrow
            statusText = "Pressed D-Pad UP"
        case 125: // Down Arrow
            statusText = "Pressed D-Pad DOWN"
        case 123: // Left Arrow
            statusText = "Pressed D-Pad LEFT"
        case 124: // Right Arrow
            statusText = "Pressed D-Pad RIGHT"
        case 6: // Z key -> A button
            statusText = "Pressed A Button (Engage / Talk)"
            if !inCombat {
                inCombat = true
                logLines.append("Engaged Wild Rabbit in combat!")
            } else {
                let dmg = Int.random(in: 12...18)
                playerTP = min(3000, playerTP + 140)
                logLines.append("Daniel attacks Wild Rabbit for \(dmg) points of damage!")
            }
        case 7: // X key -> B button
            statusText = "Pressed B Button (Cancel / Disengage)"
            if inCombat {
                inCombat = false
                logLines.append("Disengaged from battle.")
            }
        case 36: // Return key -> Start
            statusText = "Pressed START (Action Menu)"
            logLines.append("Action Menu opened.")
        case 49: // Spacebar -> Select
            statusText = "Pressed SELECT (Target cycle)"
            logLines.append("Targeting nearest foe...")
        default:
            break
        }
    }

    private func openROMInFinder() {
        let romPath = "/Users/daniel/Library/CloudStorage/GoogleDrive-danielalanbates@gmail.com/My Drive/Code/FFXI-for-Delta/rom/dist/FFXI-Advance.gba"
        let url = URL(fileURLWithPath: romPath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func launchInMednafen() {
        let romPath = "/Users/daniel/Library/CloudStorage/GoogleDrive-danielalanbates@gmail.com/My Drive/Code/FFXI-for-Delta/rom/dist/FFXI-Advance.gba"
        let task = Process()
        task.launchPath = "/opt/homebrew/bin/mednafen"
        task.arguments = ["-force_module", "gba", romPath]
        try? task.run()
        statusText = "Launched FFXI-Advance.gba in Mednafen emulator!"
    }

    private func copyTestFlightGuide() {
        let guidePath = "/Users/daniel/Library/CloudStorage/GoogleDrive-danielalanbates@gmail.com/My Drive/Code/FFXI-for-Delta/docs/TESTFLIGHT_GUIDE.md"
        let url = URL(fileURLWithPath: guidePath)
        NSWorkspace.shared.open(url)
    }
}

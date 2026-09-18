//
//  DeltaExportView.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI
import UIKit

public struct DeltaExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet: Bool = false
    @State private var exportItems: [Any] = []
    @State private var exportStatusMessage: String? = nil

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.06, green: 0.08, blue: 0.14).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Banner
                        VStack(spacing: 8) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.purple)
                            Text("Export ROM to Delta")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("Play Final Fantasy XI directly in Delta for iOS or submit it to homebrew collections.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 16)

                        // Action 1: Export GBA ROM to Delta
                        VStack(spacing: 12) {
                            Button(action: exportROMToDelta) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Open ROM in Delta / Share Sheet")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            // Action 2: Export Battery Save (.sav)
                            Button(action: exportSaveFile) {
                                HStack {
                                    Image(systemName: "sdcard.fill")
                                    Text("Export Battery Save (.sav)")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)

                        if let msg = exportStatusMessage {
                            Text(msg)
                                .font(.caption.bold())
                                .foregroundColor(.yellow)
                                .padding(.horizontal)
                        }

                        // Instructions Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("How to Play in Delta on iOS:")
                                .font(.headline)
                                .foregroundColor(.white)

                            StepRow(number: "1", text: "Tap 'Open ROM in Delta' above.")
                            StepRow(number: "2", text: "Choose 'Delta' in the iOS Share Sheet or select 'Save to Files'.")
                            StepRow(number: "3", text: "If saved to Files, open Delta, tap '+', and select FFXI-Advance.gba.")
                            StepRow(number: "4", text: "Your Vana'diel adventure will boot immediately with custom GBA skin and 60 FPS audio!")
                        }
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // Developer & License note
                        VStack(spacing: 4) {
                            Text("FFXI Advance (ROM Build v1.0.0)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("Target Core: Delta GBA / mGBA")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.7))
                            Text("Copyright (c) 2026 Daniel Bates / Bates LLC")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.purple)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityViewController(activityItems: exportItems)
            }
        }
    }

    private func exportROMToDelta() {
        guard let romURL = VanaDielEngine.shared.getROMURL() else {
            exportStatusMessage = "ROM file not found in bundle."
            return
        }

        // Try opening directly via Delta URL Scheme if Delta is installed
        let deltaScheme = URL(string: "delta://")!
        if UIApplication.shared.canOpenURL(deltaScheme) {
            exportStatusMessage = "Delta app detected! Preparing ROM..."
        }

        exportItems = [romURL]
        showShareSheet = true
    }

    private func exportSaveFile() {
        let saveURL = VanaDielEngine.shared.getSRAMURL()
        if !FileManager.default.fileExists(atPath: saveURL.path) {
            VanaDielEngine.shared.saveGameSRAM()
        }
        exportItems = [saveURL]
        showShareSheet = true
    }
}

struct StepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.purple.opacity(0.8)))
                .foregroundColor(.white)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

//
//  PlaytestFeedbackView.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI
import MessageUI

public struct PlaytestFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var engine = VanaDielEngine.shared
    @State private var feedbackText: String = ""
    @State private var feedbackType: String = "Bug Report"
    @State private var submissionStatus: String? = nil

    private let feedbackTypes = ["Bug Report", "Gameplay Balance", "Delta ROM Issue", "Feature Request"]

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.09, blue: 0.15).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Diagnostic Telemetry Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Session Telemetry")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                TelemetryBadge(title: "FPS", value: String(format: "%.1f", engine.currentFPS))
                                TelemetryBadge(title: "Zone", value: engine.currentZoneName)
                                TelemetryBadge(title: "Level", value: "Lv. \(engine.playerLevel)")
                            }

                            HStack {
                                TelemetryBadge(title: "HP", value: "\(engine.playerHP)/\(engine.playerMaxHP)")
                                TelemetryBadge(title: "MP", value: "\(engine.playerMP)/\(engine.playerMaxMP)")
                                TelemetryBadge(title: "TP", value: "\(engine.playerTP)/3000")
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal)

                        // Feedback Type Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback Category")
                                .font(.subheadline.bold())
                                .foregroundColor(.white.opacity(0.8))

                            Picker("Type", selection: $feedbackType) {
                                ForEach(feedbackTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.horizontal)

                        // Notes Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe your experience / issue:")
                                .font(.subheadline.bold())
                                .foregroundColor(.white.opacity(0.8))

                            TextEditor(text: $feedbackText)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .padding(.horizontal)

                        // Submit Button
                        Button(action: saveFeedback) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Save Report / Email to help@batesai.org")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        if let status = submissionStatus {
                            Text(status)
                                .font(.subheadline.bold())
                                .foregroundColor(.green)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("TestFlight Playtest Hub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func saveFeedback() {
        let report = """
        [FFXI Delta TestFlight Report]
        Date: \(Date())
        Type: \(feedbackType)
        Zone: \(engine.currentZoneName)
        Level: \(engine.playerLevel)
        HP: \(engine.playerHP)/\(engine.playerMaxHP)
        MP: \(engine.playerMP)/\(engine.playerMaxMP)
        TP: \(engine.playerTP)
        FPS: \(String(format: "%.1f", engine.currentFPS))
        Notes:
        \(feedbackText)
        """

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logURL = docs.appendingPathComponent("playtest_log.txt")

        if let data = report.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path),
               let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write("\n\n---\n".data(using: .utf8)!)
                handle.write(data)
                handle.closeFile()
            } else {
                try? data.write(to: logURL)
            }
        }

        submissionStatus = "Report saved to device! Shareable with developers."
        feedbackText = ""
    }
}

struct TelemetryBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
    }
}

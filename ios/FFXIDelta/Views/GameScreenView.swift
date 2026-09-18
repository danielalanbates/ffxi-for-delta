//
//  GameScreenView.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI

public struct GameScreenView: View {
    @ObservedObject var engine = VanaDielEngine.shared

    public init() {}

    public var body: some View {
        ZStack {
            Color.black

            if let frame = engine.currentFrame {
                Image(decorative: frame, scale: 1.0, orientation: .up)
                    .resizable()
                    .interpolation(.none) // Sharp nearest-neighbor retro pixel scaling
                    .aspectRatio(CGFloat(VanaDielEngine.screenWidth) / CGFloat(VanaDielEngine.screenHeight), contentMode: .fit)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    Text("Loading Vana'diel...")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // CRT Scanline subtle retro overlay
            ScanlineOverlay()
                .allowsHitTesting(false)
                .opacity(0.08)
        }
    }
}

struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let spacing: CGFloat = 3.0
                var y: CGFloat = 0
                while y < proxy.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    y += spacing
                }
            }
            .stroke(Color.black, lineWidth: 1.0)
        }
    }
}

//
//  GameScreenView.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI

public struct GameScreenView: View {
    @ObservedObject var engine = VanaDielEngine.shared
    @State private var screenImage: UIImage?

    public init() {}

    public var body: some View {
        ZStack {
            Color.black

            if let image = screenImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none) // Sharp nearest-neighbor retro pixel scaling
                    .aspectRatio(CGFloat(VanaDielEngine.screenWidth) / CGFloat(VanaDielEngine.screenHeight), contentMode: .fit)
                    .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5)
            } else {
                ProgressView("Loading Vana'diel...")
                    .foregroundColor(.white)
            }

            // CRT Scanline subtle overlay toggle
            ScanlineOverlay()
                .allowsHitTesting(false)
                .opacity(0.12)
        }
        .onReceive(engine.$pixelBuffer) { buffer in
            updateImage(from: buffer)
        }
    }

    private func updateImage(from buffer: [UInt32]) {
        let width = VanaDielEngine.screenWidth
        let height = VanaDielEngine.screenHeight

        buffer.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

            guard let context = CGContext(
                data: UnsafeMutableRawPointer(mutating: baseAddress),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ), let cgImage = context.makeImage() else {
                return
            }

            self.screenImage = UIImage(cgImage: cgImage)
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

//
//  FFXIDeltaApp.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import SwiftUI

@main
struct FFXIDeltaApp: App {
    init() {
        // Initialize hardware game controller listeners at startup
        _ = GameControllerManager.shared
    }

    var body: some Scene {
        WindowGroup {
            MainGameView()
                .preferredColorScheme(.dark)
        }
    }
}

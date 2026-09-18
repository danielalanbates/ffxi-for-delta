//
//  GameControllerManager.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import Foundation
import GameController

public final class GameControllerManager: ObservableObject {
    public static let shared = GameControllerManager()

    @Published public var connectedControllerName: String? = nil
    @Published public var hasPhysicalController: Bool = false

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )

        // Check if any controller is already connected at launch
        if let first = GCController.controllers().first {
            configureController(first)
        }
    }

    @objc private func controllerDidConnect(notification: Notification) {
        if let controller = notification.object as? GCController {
            configureController(controller)
        }
    }

    @objc private func controllerDidDisconnect(notification: Notification) {
        if GCController.controllers().isEmpty {
            connectedControllerName = nil
            hasPhysicalController = false
        }
    }

    private func configureController(_ controller: GCController) {
        connectedControllerName = controller.vendorName ?? "Game Controller"
        hasPhysicalController = true

        guard let gamepad = controller.extendedGamepad else { return }
        let engine = VanaDielEngine.shared

        // D-Pad and Left Thumbstick mapping
        gamepad.dpad.up.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.up, isDown: pressed)
        }
        gamepad.dpad.down.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.down, isDown: pressed)
        }
        gamepad.dpad.left.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.left, isDown: pressed)
        }
        gamepad.dpad.right.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.right, isDown: pressed)
        }

        // Left Analog Stick also controls D-Pad movement
        gamepad.leftThumbstick.valueChangedHandler = { _, x, y in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.up, isDown: y > 0.4)
            engine.setButtonState(button: VanaDielEngine.ControllerInput.down, isDown: y < -0.4)
            engine.setButtonState(button: VanaDielEngine.ControllerInput.left, isDown: x < -0.4)
            engine.setButtonState(button: VanaDielEngine.ControllerInput.right, isDown: x > 0.4)
        }

        // Action Buttons: A and B
        gamepad.buttonA.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.a, isDown: pressed)
        }
        gamepad.buttonB.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.b, isDown: pressed)
        }

        // Shoulder Buttons: L & R
        gamepad.leftShoulder.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.l, isDown: pressed)
        }
        gamepad.rightShoulder.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.r, isDown: pressed)
        }

        // Menu Buttons: Options / Menu (Start and Select)
        gamepad.buttonMenu.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.start, isDown: pressed)
        }
        gamepad.buttonOptions?.valueChangedHandler = { _, _, pressed in
            engine.setButtonState(button: VanaDielEngine.ControllerInput.select, isDown: pressed)
        }
    }
}

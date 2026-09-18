# FINAL FANTASY XI Advance — FFXI for Delta (iOS & GBA)

[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B%20%7C%20GBA-purple.svg)](https://batesai.org)
[![Delta Emulator](https://img.shields.io/badge/Delta-Compatible%20ROM-blue.svg)](https://github.com/rileytestut/Delta)
[![TestFlight Ready](https://img.shields.io/badge/TestFlight-Ready-green.svg)](docs/TESTFLIGHT_GUIDE.md)
[![License](https://img.shields.io/badge/License-PolyForm%20Noncommercial%201.0.0-gold.svg)](LICENSE)

An authentic recreation of **FINAL FANTASY XI** engineered to run as a Game Boy Advance ROM on **Delta for iOS** (Riley Testut's iOS emulator), paired with a full-featured **iOS TestFlight App** (`org.batesai.ffxi`) for mobile playtesting and seamless ROM export.

---

## Features at a Glance

* **Dual-Target Delivery:**
  * **Authentic GBA ROM (`FFXI-Advance.gba`):** 100% compliant ARM7TDMI binary passing all Nintendo BIOS logo & checksum checks (`0x9E`). Plays flawlessly inside Delta on iOS, mGBA, RetroArch, and real Game Boy Advance hardware.
  * **Native iOS TestFlight App (`org.batesai.ffxi`):** Built with SwiftUI and Metal. Features 60 FPS gameplay, on-screen Delta-style gamepad with tactile haptic clicks, Apple GameController support (Xbox, PS5, Switch), and in-app diagnostics.
* **One-Tap Delta Integration:**
  * In the TestFlight app, tap the **Delta** button in the top bar to export `FFXI-Advance.gba` straight into the Delta iOS app via Share Sheet or `delta://` scheme.
* **Faithful Vana'diel Gameplay:**
  * **5 Playable Races:** Hume, Elvaan, Tarutaru, Mithra, and Galka.
  * **6 Classic Starter Jobs:** Warrior (WAR), Monk (MNK), White Mage (WHM), Black Mage (BLM), Red Mage (RDM), and Thief (THF).
  * **Real-time Combat System:** Auto-attack delay, 0-3000 Tactical Points (TP), Weapon Skills (`Fast Blade`, `Combo`, `Red Lotus Blade`, `Viper Bite`), Magic Spells (`Cure`, `Stone`), Mob AI, and real-time battle log.
  * **Resting Mechanic:** `/heal` kneeling rest with progressive HP and MP recovery.
  * **Explorable Zones:** Southern San d'Oria, West Ronfaure, Port Bastok, South Gustaberg, Windurst Woods, West Sarutabaruta, Valkurm Dunes, and Selbina.
  * **Battery SRAM Save:** 64 KB battery memory (`.sav`) synced across iOS and Delta.

---

## Directory Structure

```
FFXI-for-Delta/
├── rom/                    # Game Boy Advance ROM Codebase (C + ARM Assembly)
│   ├── src/                # main.c, graphics.c, audio.c, game_state.c, crt0.s
│   ├── include/            # gba.h, graphics.h, audio.h, game_state.h
│   ├── dist/               # Compiled FFXI-Advance.gba (64 KB)
│   ├── linker.ld           # GBA memory linker script
│   ├── fix_header.py       # Nintendo header & checksum verification tool
│   └── Makefile            # Automated arm-none-eabi compilation
│
├── ios/                    # Native iOS TestFlight Application (SwiftUI + Metal)
│   ├── FFXIDelta/
│   │   ├── App/            # FFXIDeltaApp.swift
│   │   ├── Core/           # VanaDielEngine.swift (60 FPS state machine)
│   │   ├── Views/          # GameScreenView, ControllerOverlayView, MainGameView, DeltaExportView, PlaytestFeedbackView
│   │   ├── Controllers/    # GameControllerManager.swift (MFi, PS5, Xbox, Switch)
│   │   └── Resources/      # Info.plist, FFXI-Advance.gba bundle asset
│   ├── project.yml         # XcodeGen project configuration
│   └── FFXIDelta.xcodeproj # Generated Xcode project
│
├── mac/                    # Standalone macOS Desktop Companion
│   ├── FFXIAdvanceMac.swift# macOS desktop SwiftUI runner
│   └── build_mac_app.sh    # Builds and updates /Applications/FFXI Advance.app
│
├── scripts/
│   ├── build_ios.sh        # Automated pipeline (ROM compile -> iOS build)
│   └── archive_testflight.sh # Release archive and .ipa export for TestFlight
│
├── docs/
│   ├── ARCHITECTURE.md     # Technical memory map, video modes, and combat math
│   ├── TESTFLIGHT_GUIDE.md # Step-by-step TestFlight upload and playtesting setup
│   ├── DELTA_ROM_SUBMISSION.md # Delta iOS import guide & community catalog source
│   └── FUTURE_AI_ROADMAP.md# Next phases, subjob expansion, and AI continuity guide
│
├── LICENSE                 # PolyForm Noncommercial 1.0.0 (10% commercial rider)
└── README.md
```

---

## Quick Start

### 1. Build the GBA ROM
```bash
cd rom
make clean && make
# Output: dist/FFXI-Advance.gba (validated checksum: 0x9E)
```

### 2. Build and Test the iOS App (Simulator / Device)
```bash
bash scripts/build_ios.sh
```

### 3. Archive & Upload to TestFlight
Follow [docs/TESTFLIGHT_GUIDE.md](docs/TESTFLIGHT_GUIDE.md) or run:
```bash
bash scripts/archive_testflight.sh
```

### 4. Play on macOS
A fully functional companion app is installed at `/Applications/FFXI Advance.app`. Open it or rebuild with:
```bash
bash mac/build_mac_app.sh
```

---

## Controls

| Action | GBA / Delta Button | iOS Touch Gamepad | Mac Keyboard |
| :--- | :--- | :--- | :--- |
| **Move Hero** | D-Pad (Up, Down, Left, Right) | 8-Way Virtual D-Pad | Arrow Keys |
| **Engage / Talk / Confirm** | `A` Button | Red `A` Circle Button | `Z` |
| **Disengage / Cancel** | `B` Button | Magenta `B` Circle Button | `X` |
| **Action Menu** | `Start` Button | `START` Pill Button | `Return` |
| **Cycle Target** | `Select` Button | `SELECT` Pill Button | `Spacebar` |
| **Quick /heal Rest** | `L` Shoulder | `L` Shoulder Trigger | `A` |
| **Lock Target** | `R` Shoulder | `R` Shoulder Trigger | `S` |

---

## License & Attribution

Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.

Licensed under the **PolyForm Noncommercial License 1.0.0** with a **10% Commercial Revenue Rider**. Any downstream commercial distribution or incorporation requires a commercial license from Bates LLC.

* **Contact:** help@batesai.org
* **Website:** https://batesai.org

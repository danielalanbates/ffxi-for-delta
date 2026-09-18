# FFXI for Delta — System Architecture

**Project Name:** FFXI Advance / FFXI for Delta  
**Author:** Bates LLC / Daniel Bates  
**Contact:** help@batesai.org · https://batesai.org  
**License:** PolyForm Noncommercial 1.0.0 (with 10% commercial revenue rider)

---

## 1. Executive Summary

**FFXI for Delta** is an authentic recreation of *FINAL FANTASY XI* engineered to run as a native Game Boy Advance ROM on **Delta for iOS** (Riley Testut's multi-system iOS emulator), while simultaneously packaged as a native **iOS TestFlight App** (`org.batesai.ffxi`) for rapid mobile playtesting with on-screen touch controls, MFi controller support, and integrated ROM export.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           FFXI for Delta                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    FFXI-Advance (GBA ROM)                         │  │
│  │  - Authentic 240x160 Vana'diel engine (GBA Mode 3 Direct Color)   │  │
│  │  - Character Creation: 5 Races, 6 Starter Jobs, 3 Nations         │  │
│  │  - Real-time Combat: Auto-attack timer, TP (0-3000), WS, Spells   │  │
│  │  - Resting/Healing (/heal) mechanic with HP/MP regeneration       │  │
│  │  - Zones: San d'Oria, Ronfaure, Bastok, Gustaberg, Windurst,      │  │
│  │    Sarutabaruta, Valkurm Dunes, Selbina                           │  │
│  │  - Quests & Missions: Starter rank missions, Subjob quest items   │  │
│  │  - Persistent SRAM save battery for character & world progress    │  │
│  │  - Chiptune audio: Opening theme, Ronfaure, Battle theme, Victory │  │
│  └─────────────────────────────────┬─────────────────────────────────┘  │
│                                    │                                    │
│                    ┌───────────────┴───────────────┐                    │
│                    ▼                               ▼                    │
│    ┌───────────────────────────────┐ ┌───────────────────────────────┐  │
│    │     Delta Emulator on iOS     │ │    Native iOS TestFlight App  │  │
│    │  (mGBA Core in Delta)         │ │  (org.batesai.ffxi)           │  │
│    │  - Submitted / imported ROM   │ │  - Swift + SwiftUI + Metal    │  │
│    │  - Delta custom controller    │ │  - Integrated GBA runtime     │  │
│    │    skins                      │ │  - On-screen touch D-Pad &    │  │
│    │  - Cloud sync & cheat support │ │    buttons + Haptics          │  │
│    │                               │ │  - Apple GameController MFi   │  │
│    │                               │ │  - "Export ROM to Delta"      │  │
│    │                               │ │    Share sheet button         │  │
│    │                               │ │  - Signed & ready for         │  │
│    │                               │ │    TestFlight distribution    │  │
│    └───────────────────────────────┘ └───────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. GBA ROM Technical Specifications

| Parameter | Specification | Implementation Detail |
| :--- | :--- | :--- |
| **CPU Architecture** | ARM7TDMI (armv4t) | 32-bit RISC @ 16.78 MHz |
| **Instruction Set** | Thumb-1 (16-bit) + ARM (32-bit startup) | `-mcpu=arm7tdmi -mthumb-interwork -mthumb` |
| **Display Resolution** | 240 x 160 pixels | 60 Hz VBlank synchronization (`REG_VCOUNT`) |
| **Video Mode** | Mode 3 (15-bit Direct Color) | 32,768 simultaneous colors in VRAM (`0x06000000`) |
| **Sound System** | GBA DirectSound / PSG (Channels 1, 2, 4) | Modest volume level, square waves + noise slash |
| **Save Storage** | 64 KB Battery-backed SRAM (`0x0E000000`) | Header magic `0x46465849` (`FFXI`) + additive checksum |
| **Nintendo Header** | Standard 192-byte GBA Header | Logo verified, Game Title `FFXI ADVANCE`, Checksum `0x9E` |
| **ROM Size** | 64 KB (Expandable to 32 MB) | Padded to standard power-of-2 cartridge size |

### 2.1 Memory Map

```
0x00000000 - 0x00003FFF : System BIOS ROM (16 KB)
0x02000000 - 0x0203FFFF : On-board Work RAM (EWRAM) (256 KB) — .data, .bss, heaps
0x03000000 - 0x03007FFF : In-chip Work RAM (IWRAM) (32 KB) — System & IRQ Stacks
0x04000000 - 0x040003FE : Memory Mapped I/O Registers (DISPCNT, KEYINPUT, SOUND)
0x05000000 - 0x050003FF : Palette RAM (1 KB)
0x06000000 - 0x06013FFF : VRAM Mode 3 Frame Buffer (76,800 bytes)
0x08000000 - 0x09FFFFFF : Game Pak ROM (Waitstate 0) — .header, .text, .rodata
0x0E000000 - 0x0E00FFFF : Game Pak Battery SRAM (64 KB)
```

---

## 3. Game Mechanics & Systems

### 3.1 Playable Races

* **Hume:** Well-rounded statistics, adaptable in all jobs.
* **Elvaan:** Proud knightly warriors with superior Strength (STR) and Mind (MND).
* **Tarutaru:** Inherent magical mastery with the largest Mana (MP) reserves and high Intelligence (INT).
* **Mithra:** Swift hunters with elevated Dexterity (DEX) and Agility (AGI).
* **Galka:** Hulking titans with unmatched Health (HP) and Vitality (VIT).

### 3.2 Starter Jobs

* **Warrior (WAR):** Frontline combatant with heavy armor, high attack power, and the `Provoke` ability.
* **Monk (MNK):** Hand-to-hand martial artist with accelerated strike delay and devastating fist combos.
* **White Mage (WHM):** Holy practitioner wielding divine spells (`Cure`, `Dia`, `Protect`).
* **Black Mage (BLM):** Arcane spellcaster unleashing elemental destruction (`Stone`, `Fire`).
* **Red Mage (RDM):** Hybrid duelist combining swordplay with both white and black magic.
* **Thief (THF):** Nimble rogue with high critical strike chances and swift dagger speed.

### 3.3 Battle System & Tactical Points (TP)

1. **Targeting & Engagement:**
   * Press `A` near an enemy to lock on and enter combat stance.
   * Press `Select` to cycle through available targets in range.
   * Press `B` to disengage and sheath weapons.
2. **Auto-Attack Delay:**
   * Weapons have distinct delay timers (Dagger: 45 frames, Sword: 60 frames, Staff: 65 frames).
   * Auto-attacks occur automatically once engaged while standing in melee range.
3. **Tactical Points (TP):**
   * Each successful physical attack accumulates between 100 to 140 TP (maximum 3,000 TP).
   * Once TP reaches 1,000 or higher, the player can unleash Weapon Skills.
4. **Weapon Skills (WS):**
   * `Fast Blade` (Sword / 1,000 TP): High physical damage slash.
   * `Combo` (Hand-to-Hand / 1,000 TP): Rapid martial arts multi-strike.
   * `Red Lotus Blade` (Sword / 1,000 TP): Fire elemental weapon skill.
   * `Viper Bite` (Dagger / 1,000 TP): Poisoned piercing strike.
5. **Resting & Healing (`/heal`):**
   * Press `L` or select `Rest (/heal)` from the Action Menu to kneel and rest.
   * Regenerates +10% HP and MP every 60 frames (1 second) when outside combat.

---

## 4. iOS TestFlight App Architecture

* **Framework:** SwiftUI + UIKit + GameController + AVFoundation.
* **Bundle Identifier:** `org.batesai.ffxi`
* **Target Platforms:** iOS 17.0+ (iPhone and iPad), iPadOS, visionOS (compatible).
* **Key Components:**
  1. `VanaDielEngine.swift`: Central 60 FPS state machine and retro rasterizer.
  2. `GameScreenView.swift`: Crisp nearest-neighbor pixel art scaling with subtle CRT scanline effect.
  3. `ControllerOverlayView.swift`: Delta-style virtual gamepad with responsive 8-way D-Pad, haptic clicks, and action buttons.
  4. `GameControllerManager.swift`: Native Apple `GameController` integration for PlayStation, Xbox, Switch, and MFi gamepads.
  5. `DeltaExportView.swift`: One-tap export sheet allowing testers to send `FFXI-Advance.gba` directly to the Delta app on iOS!
  6. `PlaytestFeedbackView.swift`: Telemetry logger and bug reporting hub linked to `help@batesai.org`.

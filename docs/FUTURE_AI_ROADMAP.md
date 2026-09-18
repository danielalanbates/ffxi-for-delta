# FUTURE_AI_ROADMAP — FFXI for Delta & Advance

**Author:** Bates LLC / Daniel Bates  
**Contact:** help@batesai.org · https://batesai.org  
**Last Updated:** 2026-09-18  

---

## 1. Project Vision & Milestone Status

This document is the continuity guide for future AI agents and engineers working on **FFXI for Delta**. It defines the completed milestones and outlines the next 5 phases of development.

| Milestone | Scope | Status | Notes |
| :--- | :--- | :--- | :--- |
| **M1: GBA ROM Core** | ARM7TDMI assembly, Nintendo logo check, Mode 3 engine | **COMPLETE** | Checksum `0x9E`, binary `FFXI-Advance.gba` |
| **M2: Vana'diel Gameplay Engine** | Races, Jobs, Real-time combat, TP, WS, /heal, Zones | **COMPLETE** | 5 Races, 6 Jobs, 4 Zones, Mobs, NPCs |
| **M3: Battery SRAM Save System** | Persistent battery memory, checksum integrity | **COMPLETE** | 64 KB SRAM `0x0E000000`, `.sav` format |
| **M4: iOS TestFlight App** | SwiftUI, nearest-neighbor scaling, touch controls, haptics | **COMPLETE** | XcodeGen, `org.batesai.ffxi`, clean simulator build |
| **M5: Delta Export Integration** | In-app ROM share sheet, Delta URL scheme `delta://` | **COMPLETE** | Testers can send ROM to Delta in 1 tap |
| **M6: macOS Companion App** | `/Applications/FFXI Advance.app` | **COMPLETE** | Native Mac build with keyboard & emulator launch |
| **M7: Subjob (Support Job) System** | 18 subjob combinations, half-level stat cap | **PLANNED** | See Phase 2 below |
| **M8: Skillchain & Magic Burst** | Renkei elemental combinations | **PLANNED** | See Phase 3 below |
| **M9: Multiplayer Co-Op Bridge** | Delta Netplay / GBA Link Cable emulation | **RESEARCH** | See Phase 4 below |

---

## 2. Next 5 Implementation Tasks (Ordered Priority)

### Task 1: Complete Subjob (Support Job) Quest & Matrix
* **Objective:** Enable players to complete the Selbina quest (bring Damselfly Worm, Maggot, Crab Apron from Valkurm Dunes mobs) to unlock subjobs.
* **Mechanics:**
  * Subjob level caps at `floor(main_level / 2)`.
  * Player gains 50% of subjob base stats and job abilities (e.g. WAR/MNK gets `Boost`, WAR/WHM gets `Cure` and `Dia`, BLM/WHM gets divine healing).
* **Code Files:** `rom/src/game_state.c`, `ios/FFXIDelta/Core/VanaDielEngine.swift`.

### Task 2: Skillchain (Renkei) & Magic Burst Engine
* **Objective:** Implement FFXI's signature Weapon Skill combination system.
* **Mechanics:**
  * Fast Blade (Transfixion) + Combo (Impaction) -> **Fusion** Skillchain!
  * Visual banner across the battle log: `>> Skillchain: Fusion! <<`
  * Magic Burst: Casting Fire or Banish within 3 seconds of Fusion deals 2.5x burst damage.
* **Code Files:** `rom/src/combat.c` (or `game_state.c`), `audio.c` (chime trigger).

### Task 3: Zone Expansion & Notorious Monsters (NM)
* **Objective:** Add iconic starter dungeons and rare lottery spawn NMs.
* **Target Zones & NMs:**
  * **King Ranperre's Tomb / Ghelsba Outpost:** Orcish Warmachine, Spook.
  * **Palborough Mines:** Quadav miners, Mythril seams.
  * **Giddeus:** Yagudo zealots.
  * **Valkurm Dunes NM:** *Valkurm Emperor* (spawns Damselfly rare drop: Emperor Hairpin +3 DEX, +3 AGI).
* **Code Files:** `rom/src/game_state.c`, `world.c`.

### Task 4: Delta Custom Controller Skin Design
* **Objective:** Create a dedicated `.deltaskin` file for Delta with FFXI Vana'diel aesthetics.
* **Aesthetic Details:**
  * Deep navy blue marble finish matching FFXI UI windows.
  * Gold filigree directional pad and crystal jewel buttons.
  * Custom layout optimized for one-handed portrait and landscape grip on iPhone 15/16/17 Pro.
* **Output Path:** `assets/skins/FFXI-Advance.deltaskin`.

### Task 5: Delta GBA Link Cable Netplay Co-Op Prototype
* **Objective:** Investigate GBA Serial I/O (`REG_SIODATA32`, `REG_SIOCNT`) to support 2-player co-op party play over Delta's experimental wireless netplay!
* **Architecture:**
  * Player 1 acts as party leader, Player 2 joins session.
  * Synchronize mob positions and combat targets over 32-bit multi-player packets.

---

## 3. Hard Architectural Constraints (Standing Directives)

* **Disk Space:** Maintain at least 8 GB of free disk space on Daniel's Mac at all times. Avoid massive duplicate caches or uncompressed asset dumps.
* **Applications Folder:** `/Applications/FFXI Advance.app` must remain playable and up to date with changes. Never overwrite or touch `/Applications/HorizonXI.app` or `/Applications/VanaVoice.app`.
* **License & Attribution:** All new codebases must use the PolyForm Noncommercial License 1.0.0 with the 10% commercial revenue rider. Attribute copyright to `Daniel Bates / Bates LLC` (contact: `help@batesai.org`, website: `https://batesai.org`).
* **Secrets & Credentials:** Store all Apple Developer certificates, provisioning profiles, passwords, and tokens strictly in `.gitignore` files.
* **GUI Safety:** Never run automated loops that take over the Mac screen or mouse cursor.

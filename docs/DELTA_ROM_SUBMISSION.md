# FFXI Advance — Delta for iOS ROM & Submission Guide

**Project:** FFXI Advance (GBA ROM)  
**Author:** Bates LLC / Daniel Bates  
**Contact:** help@batesai.org · https://batesai.org  
**Target Emulator:** Delta for iOS (Riley Testut / AltStore)  

---

## 1. Overview

**Delta for iOS** is an all-in-one classic gaming emulator for iPhone and iPad developed by Riley Testut. Delta uses the industry-standard **mGBA** core for Game Boy Advance emulation.

`FFXI-Advance.gba` is compiled to strict Nintendo GBA hardware specifications, passing all BIOS checksum validations and Nintendo logo checks. It runs natively in:
* **Delta for iOS** (App Store and AltStore editions)
* **mGBA** (macOS, Windows, Linux, iOS)
* **RetroArch** (mGBA and VBA-Next cores)
* **Real Game Boy Advance / GBA SP / Game Boy Micro hardware** (via EZ-Flash Omega, EverDrive GBA X5)

---

## 2. Playing the ROM in Delta on iOS

### Method 1: One-Tap Transfer from TestFlight App
1. Open the **FFXI Delta** TestFlight app on your iPhone or iPad.
2. Tap the purple **Delta** button in the top navigation bar.
3. Tap **Open ROM in Delta / Share Sheet**.
4. In the iOS Share Sheet, tap the **Delta** icon.
5. Delta will automatically import `FFXI-Advance.gba` into its Game Boy Advance library with box art!

---

### Method 2: Direct File Import via iOS Files
1. Save `FFXI-Advance.gba` to your iPhone's **Files** app (iCloud Drive or On My iPhone).
2. Open **Delta**.
3. Tap the **+** icon in the upper right corner of Delta.
4. Select **Files**.
5. Navigate to and select `FFXI-Advance.gba`.
6. Tap the game in Delta's library to begin playing!

---

### Method 3: AirDrop from Mac
1. On your Mac, right-click `rom/dist/FFXI-Advance.gba`.
2. Select **Share** > **AirDrop**.
3. Select your iPhone or iPad.
4. On your iOS device, tap **Open with Delta**.

---

## 3. Battery Saves & Progress Sync (.sav)

* FFXI Advance features an on-cartridge 64 KB battery SRAM save system.
* When you save your game at a Mog House or through the Action Menu, Delta stores your save in:
  `Delta/Database/Games/FFXI-Advance.sav`
* If you played in the standalone TestFlight app first, you can export your `.sav` file from the **Delta Export** sheet and paste it into Delta to resume with your exact Level, Gil, and equipment!

---

## 4. Submitting as a Delta AltStore Source / Homebrew Catalog

Delta allows users to subscribe to custom sources (JSON feeds) to download and update homebrew games.

### 4.1 AltStore / Delta Source JSON (`source.json`)

To host FFXI Advance as an official installable ROM source in Delta:

```json
{
  "name": "BatesAI Games - FFXI for Delta",
  "identifier": "org.batesai.delta.ffxi",
  "website": "https://batesai.org",
  "games": [
    {
      "name": "FINAL FANTASY XI Advance",
      "gameID": "org.batesai.ffxi.advance",
      "system": "gba",
      "version": "1.0.0",
      "versionDate": "2026-09-18",
      "developerName": "Bates LLC",
      "summary": "An authentic recreation of Final Fantasy XI for Game Boy Advance and Delta iOS.",
      "description": "Experience Vana'diel in your pocket! Features Hume, Elvaan, Tarutaru, Mithra, and Galka races; classic Warrior, Monk, White Mage, Black Mage, Red Mage, and Thief jobs; real-time auto-attack combat, 1000 TP Weapon Skills, /heal resting, and San d'Oria, Ronfaure, and Valkurm Dunes zones.",
      "downloadURL": "https://github.com/danielalanbates/ffxi-for-delta/releases/download/v1.0.0/FFXI-Advance.gba",
      "iconURL": "https://raw.githubusercontent.com/danielalanbates/ffxi-for-delta/main/assets/icon_gba.png",
      "screenshotURLs": [
        "https://raw.githubusercontent.com/danielalanbates/ffxi-for-delta/main/assets/screen_battle.png",
        "https://raw.githubusercontent.com/danielalanbates/ffxi-for-delta/main/assets/screen_explore.png"
      ]
    }
  ]
}
```

### 4.2 Submitting to Delta Community Repositories

1. **AltStore Community Source:** Submit a pull request to community repositories like `altstore-community/sources` or `delta-skins/homebrew`.
2. **Riley Testut / Delta Discord & Reddit:** Share the `.gba` ROM and Delta AltStore source in `r/Delta_Emulator` and the official AltStore / Delta Discord server.
3. **GBADev & Itch.io:** Publish the ROM to `itch.io` under the Homebrew GBA category and `gbadev.net` for homebrew community archiving.

# FFXI for Delta — TestFlight Deployment & Playtesting Guide

**Author:** Bates LLC / Daniel Bates  
**Contact:** help@batesai.org · https://batesai.org  
**Bundle ID:** `org.batesai.ffxi`  
**App Name:** FFXI Delta  

---

## 1. Prerequisites

To upload and distribute **FFXI Delta** on TestFlight, you need:
* Active Apple Developer Account (`developer.apple.com`)
* Mac with Xcode 15+ or Xcode 16+ (installed at `/Applications/Xcode.app`)
* App Store Connect access (`appstoreconnect.apple.com`)

---

## 2. App Store Connect Setup (One-Time)

1. **Register the App ID:**
   * Go to **Certificates, Identifiers & Profiles** > **Identifiers**.
   * Click **+** to add an App ID (`App`).
   * **Description:** `FFXI Delta for iOS`
   * **Bundle ID (Explicit):** `org.batesai.ffxi`
   * Under Capabilities, check **Game Center** (optional) and **Extended Virtual Controller / Game Controller**.
   * Click **Register**.

2. **Create the New App in App Store Connect:**
   * Go to [App Store Connect Apps](https://appstoreconnect.apple.com/apps).
   * Click the **+** button > **New App**.
   * **Platforms:** iOS
   * **Name:** `FFXI Delta` (or `FFXI Advance - Vana'diel`)
   * **Primary Language:** English (U.S.)
   * **Bundle ID:** Select `org.batesai.ffxi`
   * **SKU:** `FFXI-DELTA-IOS-01`
   * **User Access:** Full Access
   * Click **Create**.

3. **Export Compliance (Pre-configured):**
   * In `Info.plist`, the key `ITSAppUsesNonExemptEncryption` is already set to `<false/>`.
   * TestFlight will automatically bypass the cryptographic export compliance question when processing new builds.

---

## 3. Signing & Building in Xcode

### Option A: Using Xcode GUI

1. Open the project in Xcode:
   ```bash
   open "/Users/daniel/Library/CloudStorage/GoogleDrive-danielalanbates@gmail.com/My Drive/Code/FFXI-for-Delta/ios/FFXIDelta.xcodeproj"
   ```
2. In the Project Navigator, select the **FFXIDelta** project root.
3. Select the **FFXIDelta** target > **Signing & Capabilities**.
4. Check **Automatically manage signing**.
5. Select your Apple Developer Account **Team** from the dropdown.
6. In the top destination bar, select **Any iOS Device (arm64)**.
7. Go to **Product** > **Archive**.
8. When the Organizer window opens, click **Distribute App** > **TestFlight & App Store** > **Upload**.

---

### Option B: Automated Terminal Release Pipeline

You can run the automated script included in this repository:

```bash
cd "/Users/daniel/Library/CloudStorage/GoogleDrive-danielalanbates@gmail.com/My Drive/Code/FFXI-for-Delta"
bash scripts/archive_testflight.sh
```

This will:
1. Compile the latest GBA ROM (`rom/dist/FFXI-Advance.gba`).
2. Sync the ROM into the iOS Resources directory.
3. Build the iOS Release Archive (`dist/testflight/FFXIDelta.xcarchive`).
4. Export the signed `.ipa` package ready for upload.

To upload the IPA directly to TestFlight from terminal:

```bash
xcrun altool --upload-app \
  -f "dist/testflight/export/FFXIDelta.ipa" \
  -t ios \
  -u "danielalanbates@gmail.com" \
  -p "<app-specific-password>"
```

*(Note: Generate an app-specific password at `appleid.apple.com` > Security > App-Specific Passwords).*

Alternatively, you can use the free **Apple Transporter** app from the Mac App Store:
* Open Transporter.
* Drag and drop `FFXIDelta.ipa`.
* Click **Deliver**.

---

## 4. Setting Up TestFlight Playtesting

### 4.1 Internal Testing (Immediate)
* Go to **App Store Connect** > **FFXI Delta** > **TestFlight** tab.
* Under **Internal Groups**, add yourself and your core team.
* Builds become available to internal testers immediately upon processing (~5-10 minutes) without requiring App Review!

### 4.2 External Testing & Public Link
* Under **External Groups**, click **+** (e.g., "FFXI Community Playtesters").
* Add external testers via email or enable **Public Link**.
* Provide a brief "What to Test" description:
  > *"Test character creation across all 5 races and 6 starter jobs. Explore San d'Oria, Ronfaure, and Valkurm Dunes. Engage in real-time combat, test Weapon Skills at 1000 TP, and test exporting the ROM to Delta using the top-bar Delta button."*
* Apple will perform a light beta review (typically approved in 24 hours), after which anyone with the link can install and playtest on their iPhone or iPad!

---

## 5. What Testers Can Do in the TestFlight App

* **Play Standalone:** Full 60 FPS gameplay on iOS with touch controls or physical Bluetooth controllers.
* **Export to Delta:** Tap the **Delta** button in the top bar to export `FFXI-Advance.gba` directly to the Delta app on the same iPhone.
* **Transfer Saves:** Export `.sav` battery save files to continue playing in Delta without losing character progression.
* **Submit Diagnostics:** Use the in-app **Playtest Hub** button to view session telemetry (FPS, current zone, player coordinates) and log bug reports.

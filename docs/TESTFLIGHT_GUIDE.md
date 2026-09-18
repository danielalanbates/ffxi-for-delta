# FFXI for Delta — TestFlight Deployment & Playtesting Guide

**Author:** Bates LLC / Daniel Bates  
**Contact:** help@batesai.org · https://batesai.org  
**Bundle ID:** `org.batesai.ffxi` (Registered ID: `W2BK7MXMZK`, Team: `MG4YW8XX2Z`)  
**Provisioning Profile:** `FFXI Delta AppStore Profile` (`86d1ee98-d13b-4fbe-9360-0803f06c8217`)  
**Signing Identity:** `Apple Distribution: Daniel Bates (MG4YW8XX2Z)`  
**App Name:** `FFXI Delta`  

---

## 1. Quick Start: One-Click TestFlight Pipeline

The repository includes a fully automated, headless release pipeline that compiles, signs with your Apple Distribution identity, packages the `.ipa`, and uploads to TestFlight:

```bash
cd "/Users/daniel/Library/CloudStorage/GoogleDrive-danielalanbates@gmail.com/My Drive/Code/FFXI-for-Delta"
bash scripts/deploy_testflight.sh
```

This pipeline executes:
1. `scripts/package_testflight_ipa.py`: Unlocks the CI keychain, embeds the distribution provisioning profile, signs the binary with your Apple Distribution certificate, and outputs `dist/testflight/export/FFXIDelta.ipa`.
2. `scripts/upload_testflight.sh`: Validates and uploads `FFXIDelta.ipa` to TestFlight using `xcrun altool` and your App Store Connect API Key (`32R84GFV2F`).
3. `scripts/invite_testflight_tester.py`: Adds `danielalanbates@gmail.com` to the TestFlight beta testing group and triggers the email invitation with the installation link.

---

## 2. App Store Connect Setup (One-Time App Entry)

Apple's public App Store Connect REST API does not allow programmatically creating the initial root Application entity (`POST /v1/apps` returns `403 Forbidden`). This 1-minute step is performed once in the web portal:

1. Open [App Store Connect Apps](https://appstoreconnect.apple.com/apps).
2. Click the **+** button > **New App**.
3. Fill in the fields:
   * **Platforms:** `iOS`
   * **Name:** `FFXI Delta` (or `FFXI Advance - Vana'diel`)
   * **Primary Language:** `English (U.S.)`
   * **Bundle ID:** Select `org.batesai.ffxi` (already registered to team `MG4YW8XX2Z`)
   * **SKU:** `org.batesai.ffxi`
   * **User Access:** Full Access
4. Click **Create**.

Once created, run:
```bash
bash scripts/deploy_testflight.sh
```
The IPA uploads immediately, Apple processes the build (~5-10 minutes), and TestFlight sends an invitation email to `danielalanbates@gmail.com`!

---

## 3. What Testers Can Do in the TestFlight App

* **Play Final Fantasy XI Advance:** Full 60 FPS gameplay on iPhone & iPad with native touch controls, virtual D-Pad, action buttons, and haptic feedback.
* **Game Controller Support:** Plug in or connect any MFi, Xbox, DualShock, or DualSense controller.
* **One-Tap Export to Delta:** Tap the **Delta** button in the navigation bar to export `FFXI-Advance.gba` directly to the Delta iOS app installed on the device.
* **Export Battery Save:** Export `.sav` SRAM save files to synchronize character progress between the standalone app and Delta emulator.
* **Playtest Feedback Hub:** View live FPS, memory usage, current zone ID, and submit playtest telemetry.

---

## 4. Encryption & Export Compliance

In `ios/FFXIDelta/Resources/Info.plist`, `ITSAppUsesNonExemptEncryption` is set to `<false/>`. TestFlight will automatically mark new builds as compliant without holding them for manual cryptography review questions.

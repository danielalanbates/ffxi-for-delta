#!/usr/bin/env python3
"""
FFXI for Delta - TestFlight Release IPA Signer & Packager
Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
"""
import os
import sys
import shutil
import plistlib
import subprocess

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    app_src = os.path.join(root_dir, "dist/testflight/FFXIDelta.xcarchive/Products/Applications/FFXI Delta.app")
    export_dir = os.path.join(root_dir, "dist/testflight/export")
    payload_dir = os.path.join(export_dir, "Payload")
    app_dst = os.path.join(payload_dir, "FFXI Delta.app")
    ipa_path = os.path.join(export_dir, "FFXIDelta.ipa")
    prof_path = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles/2W97RZ49S8.mobileprovision")
    kc_path = os.path.expanduser("~/Library/Keychains/endgame-ci.keychain-db")
    pw_file = os.path.expanduser("~/Library/Application Support/BatesAI/keys/endgame-signing/keychain-password.txt")

    if not os.path.exists(app_src):
        print(f"Error: Archive app not found at {app_src}")
        sys.exit(1)

    print("==> Step 1: Unlocking CI keychain for headless distribution signing...")
    if os.path.exists(pw_file) and os.path.exists(kc_path):
        with open(pw_file) as f:
            pw = f.read().strip()
        subprocess.run(["security", "unlock-keychain", "-p", pw, kc_path], check=True)
        subprocess.run(["security", "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:", "-s", "-k", pw, kc_path], check=True)
    else:
        print("Warning: CI keychain not found; falling back to default login keychain.")

    print("==> Step 2: Preparing IPA Payload structure...")
    if os.path.exists(export_dir):
        shutil.rmtree(export_dir)
    os.makedirs(payload_dir, exist_ok=True)
    shutil.copytree(app_src, app_dst)

    print("==> Step 3: Embedding distribution provisioning profile...")
    if os.path.exists(prof_path):
        shutil.copy(prof_path, os.path.join(app_dst, "embedded.mobileprovision"))
    else:
        print(f"Error: Provisioning profile not found at {prof_path}")
        sys.exit(1)

    print("==> Step 4: Extracting profile entitlements...")
    raw_prof = subprocess.check_output(["security", "cms", "-D", "-i", prof_path])
    profile_data = plistlib.loads(raw_prof)
    entitlements = profile_data["Entitlements"]
    entitlements_path = "/tmp/ffxi_entitlements.plist"
    with open(entitlements_path, "wb") as f:
        plistlib.dump(entitlements, f)

    print("==> Step 5: Code signing app bundle with Apple Distribution...")
    sign_cmd = [
        "codesign", "-f", "-s", "EC92881F03ECB13449DDD839E2E276767C1C1F92",
        "--keychain", kc_path,
        "--entitlements", entitlements_path,
        "--generate-entitlement-der",
        app_dst
    ]
    subprocess.run(sign_cmd, check=True)

    print("==> Step 6: Verifying signature...")
    subprocess.run(["codesign", "-vvv", "--deep", "--strict", app_dst], check=True)

    print("==> Step 7: Packaging FFXIDelta.ipa...")
    subprocess.run(["zip", "-q", "-r", "-y", ipa_path, "Payload"], cwd=export_dir, check=True)

    size_mb = os.path.getsize(ipa_path) / (1024 * 1024)
    print(f"==> SUCCESS: Created signed IPA: {ipa_path} ({size_mb:.2f} MB)")

if __name__ == "__main__":
    main()

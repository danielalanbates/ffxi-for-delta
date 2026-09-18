#!/usr/bin/env bash
# =============================================================================
# FFXI for Delta - Automated iOS Simulator & Device Build Script
# Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios"
ROM_DIR="$ROOT_DIR/rom"

echo "========================================================"
echo "  FFXI for Delta - iOS Build Pipeline"
echo "========================================================"

# Step 1: Recompile GBA ROM to ensure latest game assets
echo "--> Step 1: Building GBA ROM (FFXI-Advance.gba)..."
make -C "$ROM_DIR" clean
make -C "$ROM_DIR"

# Step 2: Sync compiled ROM to iOS Resources
echo "--> Step 2: Syncing ROM into iOS app bundle..."
mkdir -p "$IOS_DIR/FFXIDelta/Resources"
cp "$ROM_DIR/dist/FFXI-Advance.gba" "$IOS_DIR/FFXIDelta/Resources/FFXI-Advance.gba"

# Step 3: Regenerate Xcode project via XcodeGen
echo "--> Step 3: Regenerating Xcode Project..."
cd "$IOS_DIR"
xcodegen generate

# Step 4: Build for iOS Simulator
echo "--> Step 4: Compiling for iOS Simulator (arm64)..."
xcodebuild -project FFXIDelta.xcodeproj \
           -scheme FFXIDelta \
           -destination "generic/platform=iOS Simulator" \
           clean build \
           CODE_SIGNING_ALLOWED=NO \
           CODE_SIGNING_REQUIRED=NO

echo "========================================================"
echo "  BUILD SUCCESSFUL: FFXIDelta is ready for testing!"
echo "========================================================"

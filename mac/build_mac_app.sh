#!/usr/bin/env bash
# =============================================================================
# Build script for /Applications/FFXI Advance.app (macOS companion)
# Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="/Applications/FFXI Advance.app"
CONTENTS="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "--> Compiling macOS companion binary..."
swiftc -parse-as-library -O "$SCRIPT_DIR/FFXIAdvanceMac.swift" -o /tmp/FFXIAdvanceBinary

echo "--> Creating app bundle at: $APP_PATH..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

mv /tmp/FFXIAdvanceBinary "$MACOS_DIR/FFXI Advance"
chmod +x "$MACOS_DIR/FFXI Advance"

# Info.plist
cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>FFXI Advance</string>
	<key>CFBundleExecutable</key>
	<string>FFXI Advance</string>
	<key>CFBundleIdentifier</key>
	<string>org.batesai.ffxi.mac</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>FFXI Advance</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
EOF

# Copy ROM into Resources
cp "$ROOT_DIR/rom/dist/FFXI-Advance.gba" "$RESOURCES_DIR/FFXI-Advance.gba"

echo "==> Successfully installed and updated /Applications/FFXI Advance.app"

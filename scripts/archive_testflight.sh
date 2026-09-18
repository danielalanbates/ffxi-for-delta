#!/usr/bin/env bash
# =============================================================================
# FFXI for Delta - TestFlight Archive & Upload Script
# Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios"
OUTPUT_DIR="$ROOT_DIR/dist/testflight"
ARCHIVE_PATH="$OUTPUT_DIR/FFXIDelta.xcarchive"
EXPORT_PATH="$OUTPUT_DIR/export"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$EXPORT_PATH"

echo "========================================================"
echo "  FFXI for Delta - TestFlight Release Pipeline"
echo "========================================================"

# Step 1: Create ExportOptions.plist for App Store / TestFlight
cat << 'EOF' > "$OUTPUT_DIR/ExportOptions.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>export</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string></string>
</dict>
</plist>
EOF

echo "--> Step 1: Archiving FFXIDelta for iOS Generic Device..."
cd "$IOS_DIR"
xcodebuild archive \
    -project FFXIDelta.xcodeproj \
    -scheme FFXIDelta \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGNING_ALLOWED=YES

echo "--> Step 2: Exporting IPA..."
if xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$OUTPUT_DIR/ExportOptions.plist" 2>/dev/null; then
    echo "==> IPA Generated at: $EXPORT_PATH/FFXIDelta.ipa"
else
    echo "==> Note: Automatic signing requires your Apple Developer Account Team ID configured in Xcode."
    echo "==> The .xcarchive has been successfully generated at: $ARCHIVE_PATH"
fi

echo "========================================================"
echo "  TESTFLIGHT UPLOAD COMMAND (When signed):"
echo "  xcrun altool --upload-app -f '$EXPORT_PATH/FFXIDelta.ipa' -t ios -u help@batesai.org -p <app-specific-password>"
echo "========================================================"

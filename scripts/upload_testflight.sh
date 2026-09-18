#!/usr/bin/env bash
# =============================================================================
# FFXI for Delta - Upload to TestFlight
# Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IPA_PATH="$ROOT_DIR/dist/testflight/export/FFXIDelta.ipa"

API_KEY="32R84GFV2F"
ISSUER_ID="67d2d531-0ef2-43f5-8319-7505313c9fd1"

if [ ! -f "$IPA_PATH" ]; then
    echo "==> IPA not found, packaging now..."
    python3 "$SCRIPT_DIR/package_testflight_ipa.py"
fi

echo "========================================================"
echo "  Uploading FFXI Delta to App Store Connect / TestFlight"
echo "  IPA: $IPA_PATH"
echo "========================================================"

xcrun altool --upload-app \
    -f "$IPA_PATH" \
    --type ios \
    --api-key "$API_KEY" \
    --api-issuer "$ISSUER_ID" \
    --show-progress

echo "==> Upload completed successfully!"

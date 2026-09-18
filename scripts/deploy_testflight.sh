#!/usr/bin/env bash
# =============================================================================
# FFXI for Delta - One-Step TestFlight Deployment Pipeline
# Packages signed IPA, uploads via altool, and invites danielalanbates@gmail.com
# Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================================"
echo "  FFXI for Delta - TestFlight Deployment & Playtesting"
echo "========================================================"

echo "--> Step 1: Packaging & Signing Production IPA..."
python3 "$SCRIPT_DIR/package_testflight_ipa.py"

echo "--> Step 2: Checking App Store Connect App Record..."
python3 "$SCRIPT_DIR/invite_testflight_tester.py"

echo "--> Step 3: Uploading IPA via altool..."
bash "$SCRIPT_DIR/upload_testflight.sh"

echo "--> Step 4: Dispatching Tester Invitation..."
python3 "$SCRIPT_DIR/invite_testflight_tester.py"

echo "========================================================"
echo "  DEPLOYMENT COMPLETE!"
echo "========================================================"

#!/usr/bin/env bash
# Pre-release verification script for MLAIX.
# Run before tagging a release or distributing.

set -e

echo "=== MLAIX Pre-Release Verification ==="

echo ""
echo "1. Building MLAIX (macOS, release)..."
swift build -c release --product MLAIX

echo ""
echo "2. Building MLAIXiOS..."
swift build --product MLAIXiOS

echo ""
echo "3. Building MLAIXtvos..."
swift build --product MLAIXtvos

echo ""
echo "4. Running tests..."
swift test

echo ""
echo "=== All checks passed ==="
echo "Next: Update version in MLAIX/Info.plist, run setup.sh for marp signing, then distribute."

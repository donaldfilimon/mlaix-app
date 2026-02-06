#!/usr/bin/env bash
# Run MLAIX tests.
#
# Desktop interaction tests (PromptDesktopInteractionTests) require:
#   - Display access (run in a terminal, not headless CI)
#   - MLAIX_UI_INTERACTION_TESTS=1
#
# Usage:
#   ./scripts/run-ui-tests.sh              # Unit tests only
#   MLAIX_UI_INTERACTION_TESTS=1 ./scripts/run-ui-tests.sh  # Include desktop interaction tests

set -e
cd "$(dirname "$0")/.."

echo "Building MLAIX..."
swift build

echo "Running tests..."
swift test

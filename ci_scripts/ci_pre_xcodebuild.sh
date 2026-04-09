#!/bin/bash
set -euo pipefail

# ci_pre_xcodebuild.sh — Runs before xcodebuild in Xcode Cloud.
# Sets the build number (CURRENT_PROJECT_VERSION) to CI_BUILD_NUMBER
# so every App Store Connect upload has a unique, auto-incrementing build number.

echo "--- Pre-xcodebuild: Setting build number ---"

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
    echo "Warning: CI_BUILD_NUMBER not set, skipping version bump."
    exit 0
fi

PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/Habitual.xcodeproj/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
    echo "Error: project.pbxproj not found at $PBXPROJ"
    exit 1
fi

# Read current build number for logging
CURRENT=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PBXPROJ" | sed 's/[^0-9]//g')
echo "Current build number: $CURRENT"
echo "Setting build number to CI_BUILD_NUMBER: $CI_BUILD_NUMBER"

# Update ALL targets' CURRENT_PROJECT_VERSION to the Xcode Cloud build number.
# This keeps all targets (app, watch, widgets, complications) in sync.
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" "$PBXPROJ"

# Verify the update
UPDATED_COUNT=$(grep -c "CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;" "$PBXPROJ")
echo "Updated $UPDATED_COUNT build settings to version $CI_BUILD_NUMBER"

echo "--- Pre-xcodebuild complete ---"

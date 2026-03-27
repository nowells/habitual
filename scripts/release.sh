#!/bin/bash
set -euo pipefail

# Usage: ./scripts/release.sh [--bump-only] [--ios-only] [--mac-only]
#
# Bumps CURRENT_PROJECT_VERSION, archives for iOS + Mac Catalyst,
# and distributes both to App Store Connect.

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/Habitual.xcodeproj"
SCHEME="Habitual"
BUILD_DIR="$PROJECT_DIR/build"
PBXPROJ="$PROJECT/project.pbxproj"

BUMP_ONLY=false
SKIP_IOS=false
SKIP_MAC=false

for arg in "$@"; do
    case "$arg" in
        --bump-only) BUMP_ONLY=true ;;
        --ios-only)  SKIP_MAC=true ;;
        --mac-only)  SKIP_IOS=true ;;
        --help|-h)
            echo "Usage: $0 [--bump-only] [--ios-only] [--mac-only]"
            echo ""
            echo "  --bump-only   Only bump the build number, skip archive/upload"
            echo "  --ios-only    Only archive and upload iOS"
            echo "  --mac-only    Only archive and upload Mac Catalyst"
            exit 0
            ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# ── Step 1: Bump CURRENT_PROJECT_VERSION ────────────────────────────────────

# Read current version (take the first occurrence)
CURRENT=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PBXPROJ" | sed 's/[^0-9]//g')
NEXT=$((CURRENT + 1))

echo "📦 Bumping CURRENT_PROJECT_VERSION: $CURRENT → $NEXT"

# Replace all occurrences in the pbxproj (all targets stay in sync)
sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT;/CURRENT_PROJECT_VERSION = $NEXT;/g" "$PBXPROJ"

# Verify the bump
VERIFY=$(grep -c "CURRENT_PROJECT_VERSION = $NEXT;" "$PBXPROJ")
echo "   ✓ Updated $VERIFY build settings to version $NEXT"

if [ "$BUMP_ONLY" = true ]; then
    echo "✅ Version bumped. Skipping archive/upload (--bump-only)."
    exit 0
fi

# ── Step 2: Clean build directory ───────────────────────────────────────────

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── Step 3: Archive & distribute iOS ────────────────────────────────────────

if [ "$SKIP_IOS" = false ]; then
    echo ""
    echo "🍎 Archiving for iOS..."
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "generic/platform=iOS" \
        -archivePath "$BUILD_DIR/Habitual-iOS.xcarchive" \
        -allowProvisioningUpdates \
        | xcpretty || xcodebuild archive \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "generic/platform=iOS" \
            -archivePath "$BUILD_DIR/Habitual-iOS.xcarchive" \
            -allowProvisioningUpdates

    echo "📤 Distributing iOS to App Store Connect..."
    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/Habitual-iOS.xcarchive" \
        -exportOptionsPlist "$PROJECT_DIR/ExportOptions-iOS.plist" \
        -exportPath "$BUILD_DIR/export-ios" \
        -allowProvisioningUpdates

    echo "   ✓ iOS upload complete"
fi

# ── Step 4: Archive & distribute Mac Catalyst ───────────────────────────────

if [ "$SKIP_MAC" = false ]; then
    echo ""
    echo "🖥️  Archiving for Mac Catalyst..."
    xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "generic/platform=macOS,variant=Mac Catalyst" \
        -archivePath "$BUILD_DIR/Habitual-macCatalyst.xcarchive" \
        -allowProvisioningUpdates \
        | xcpretty || xcodebuild archive \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "generic/platform=macOS,variant=Mac Catalyst" \
            -archivePath "$BUILD_DIR/Habitual-macCatalyst.xcarchive" \
            -allowProvisioningUpdates

    echo "📤 Distributing Mac Catalyst to App Store Connect..."
    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/Habitual-macCatalyst.xcarchive" \
        -exportOptionsPlist "$PROJECT_DIR/ExportOptions-macCatalyst.plist" \
        -exportPath "$BUILD_DIR/export-mac" \
        -allowProvisioningUpdates

    echo "   ✓ Mac Catalyst upload complete"
fi

# ── Done ────────────────────────────────────────────────────────────────────

MARKETING=$(grep -m1 'MARKETING_VERSION = ' "$PBXPROJ" | sed 's/[^0-9.]//g')
echo ""
echo "✅ Release complete — v${MARKETING} (build $NEXT)"
echo "   Check App Store Connect for processing status."

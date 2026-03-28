#!/bin/bash
set -eo pipefail

# Launch Habitual on Mac Catalyst, iPhone Simulator, and Watch Simulator
# in parallel with gum spinners and color-coded log output.
# Optionally select a subset of targets via gum choose.

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/Habitual.xcodeproj"
DERIVED_DATA_MAC="$PROJECT_DIR/.build/DerivedData-mac"
DERIVED_DATA_IOS="$PROJECT_DIR/.build/DerivedData-ios"
DERIVED_DATA_WATCH="$PROJECT_DIR/.build/DerivedData-watch"
LOGS_DIR=$(mktemp -d)

# ── Choose targets ──────────────────────────────────────────────────────────

# Accept targets as arguments (e.g. ./run-all.sh mac ios) or prompt interactively.
if [ $# -gt 0 ]; then
    SELECTED="$*"
else
    SELECTED=$(gum choose --no-limit --selected "Mac,iPhone,Watch" \
        "Mac" "iPhone" "Watch")
fi

if [ -z "$SELECTED" ]; then
    echo "No targets selected."
    exit 0
fi

RUN_MAC=false
RUN_IOS=false
RUN_WATCH=false

for target in $SELECTED; do
    case "$target" in
        Mac|mac)     RUN_MAC=true ;;
        iPhone|iphone|ios|iOS) RUN_IOS=true ;;
        Watch|watch)  RUN_WATCH=true ;;
    esac
done

# ── Pick simulators (only if needed) ────────────────────────────────────────

IPHONE_SIM=""
WATCH_SIM=""
IPHONE_NAME=""
WATCH_NAME=""

if [ "$RUN_IOS" = true ] || [ "$RUN_WATCH" = true ]; then
    # Prefer an existing iPhone+Watch pair so iCloud account carries over.
    # Falls back to picking individually if no pair exists.
    read -r IPHONE_SIM WATCH_SIM < <(python3 -c "
import json, subprocess, sys

pairs = json.loads(subprocess.check_output(
    ['xcrun', 'simctl', 'list', 'pairs', '-j'], text=True))
devices = json.loads(subprocess.check_output(
    ['xcrun', 'simctl', 'list', 'devices', 'available', '-j'], text=True))

# Build set of available UDIDs
available = set()
for runtime, devs in devices['devices'].items():
    for d in devs:
        available.add(d['udid'])

# Find best existing pair (prefer non-Ultra watch, non-Max iPhone)
best_pair = None
for pid, pair in pairs.get('pairs', {}).items():
    phone_udid = pair.get('phone', {}).get('udid', '')
    watch_udid = pair.get('watch', {}).get('udid', '')
    if phone_udid not in available or watch_udid not in available:
        continue
    phone_name = pair.get('phone', {}).get('name', '')
    watch_name = pair.get('watch', {}).get('name', '')
    if 'Ultra' in watch_name:
        continue
    best_pair = (phone_udid, watch_udid)
    break

if best_pair:
    print(best_pair[0], best_pair[1])
    sys.exit()

# Fallback: pick individually
phone = None
for runtime, devs in devices['devices'].items():
    if 'iOS' in runtime:
        for d in devs:
            if 'iPhone' in d['name']:
                if phone is None or ('Pro' in d['name'] and 'Max' not in d['name']):
                    phone = d['udid']
watch = None
for runtime, devs in devices['devices'].items():
    if 'watchOS' in runtime:
        for d in devs:
            if 'Ultra' not in d['name']:
                watch = d['udid']
                break
        if watch:
            break

print(phone or '', watch or '')
" 2>/dev/null)

    if [ -n "$IPHONE_SIM" ]; then
        IPHONE_NAME=$(xcrun simctl list devices available | grep "$IPHONE_SIM" | sed 's/(.*//' | xargs)
    fi
    if [ -n "$WATCH_SIM" ]; then
        WATCH_NAME=$(xcrun simctl list devices available | grep "$WATCH_SIM" | sed 's/(.*//' | xargs)
    fi
fi

gum style --bold --foreground 212 "Habitual — Multi-Platform Runner"
echo ""
[ "$RUN_IOS" = true ]   && gum style --foreground 39  "  📱 iPhone:  $IPHONE_NAME"
[ "$RUN_WATCH" = true ] && gum style --foreground 208 "  ⌚ Watch:   $WATCH_NAME"
[ "$RUN_MAC" = true ]   && gum style --foreground 141 "  🖥️  Mac:     this Mac (Catalyst)"
echo ""

# ── Cleanup on exit ──────────────────────────────────────────────────────────

ALL_PIDS=""

cleanup() {
    echo ""
    gum style --foreground 196 "🛑 Stopping all processes..."
    for pid in $ALL_PIDS; do
        kill "$pid" 2>/dev/null || true
    done
    if [ "$RUN_IOS" = true ] && [ -n "$IPHONE_SIM" ]; then
        xcrun simctl terminate "$IPHONE_SIM" "com.habitual-helper.app" 2>/dev/null || true
    fi
    if [ "$RUN_WATCH" = true ] && [ -n "$WATCH_SIM" ]; then
        xcrun simctl terminate "$WATCH_SIM" "com.habitual-helper.app.watchkitapp" 2>/dev/null || true
    fi
    wait 2>/dev/null || true
    rm -rf "$LOGS_DIR"
    gum style --foreground 46 "✅ Done."
}

trap cleanup EXIT INT TERM

# ── Boot & pair simulators ───────────────────────────────────────────────────

if [ "$RUN_IOS" = true ] || [ "$RUN_WATCH" = true ]; then
    gum spin --spinner dot --title "Booting simulators..." -- bash -c "
        [ '$RUN_IOS' = true ]   && xcrun simctl boot '$IPHONE_SIM' 2>/dev/null || true
        [ '$RUN_WATCH' = true ] && xcrun simctl boot '$WATCH_SIM' 2>/dev/null || true
    "

    # Pair watch with iPhone (if both are running)
    if [ "$RUN_IOS" = true ] && [ "$RUN_WATCH" = true ]; then
        EXISTING_PAIR=$(xcrun simctl list pairs -j 2>/dev/null \
            | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pid, pair in data.get('pairs', {}).items():
    phone = pair.get('phone', {}).get('udid', '')
    watch = pair.get('watch', {}).get('udid', '')
    if phone == '$IPHONE_SIM' and watch == '$WATCH_SIM':
        print(pid); sys.exit()
" 2>/dev/null || true)

        if [ -z "$EXISTING_PAIR" ]; then
            gum spin --spinner dot --title "Pairing Watch with iPhone..." -- \
                xcrun simctl pair "$WATCH_SIM" "$IPHONE_SIM" 2>/dev/null || true
        fi
    fi

    open -a Simulator
fi

# ── Color helpers ────────────────────────────────────────────────────────────

COLOR_MAC="\033[38;5;141m"    # purple
COLOR_IOS="\033[38;5;39m"     # blue
COLOR_WATCH="\033[38;5;208m"  # orange
COLOR_ERR="\033[38;5;196m"    # red
COLOR_WARN="\033[38;5;220m"   # yellow
COLOR_RESET="\033[0m"

stream_logs() {
    local tag="$1"
    local color="$2"
    while IFS= read -r line; do
        if echo "$line" | grep -qiE '(error|fatal|crash|exception|assert)'; then
            printf "${COLOR_ERR}[%s] %s${COLOR_RESET}\n" "$tag" "$line"
        elif echo "$line" | grep -qiE '(warning|⚠)'; then
            printf "${COLOR_WARN}[%s] %s${COLOR_RESET}\n" "$tag" "$line"
        else
            printf "${color}[%s]${COLOR_RESET} %s\n" "$tag" "$line"
        fi
    done
}

# ── Build targets in parallel ────────────────────────────────────────────────

MAC_LOG="$LOGS_DIR/mac-build.log"
IOS_LOG="$LOGS_DIR/ios-build.log"
WATCH_LOG="$LOGS_DIR/watch-build.log"

# Each build writes exit code to a status file
run_build() {
    local logfile="$1"
    local statusfile="$2"
    shift 2
    if "$@" > "$logfile" 2>&1; then
        echo "ok" > "$statusfile"
    else
        echo "fail" > "$statusfile"
    fi
}

BUILD_PIDS=""
BUILD_SPINNER_TARGETS=""

if [ "$RUN_MAC" = true ]; then
    run_build "$MAC_LOG" "$LOGS_DIR/mac.status" \
        xcodebuild build \
        -project "$PROJECT" \
        -scheme Habitual \
        -destination "generic/platform=macOS,variant=Mac Catalyst" \
        -configuration Debug \
        -allowProvisioningUpdates \
        -derivedDataPath "$DERIVED_DATA_MAC" &
    MAC_BUILD_PID=$!
    ALL_PIDS="$ALL_PIDS $MAC_BUILD_PID"
    BUILD_PIDS="$BUILD_PIDS $MAC_BUILD_PID"
    BUILD_SPINNER_TARGETS="${BUILD_SPINNER_TARGETS:+$BUILD_SPINNER_TARGETS, }Mac"
fi

if [ "$RUN_IOS" = true ]; then
    run_build "$IOS_LOG" "$LOGS_DIR/ios.status" \
        xcodebuild build \
        -project "$PROJECT" \
        -scheme Habitual \
        -destination "platform=iOS Simulator,id=$IPHONE_SIM" \
        -configuration Debug \
        -allowProvisioningUpdates \
        -derivedDataPath "$DERIVED_DATA_IOS" &
    IOS_BUILD_PID=$!
    ALL_PIDS="$ALL_PIDS $IOS_BUILD_PID"
    BUILD_PIDS="$BUILD_PIDS $IOS_BUILD_PID"
    BUILD_SPINNER_TARGETS="${BUILD_SPINNER_TARGETS:+$BUILD_SPINNER_TARGETS, }iOS"
fi

if [ "$RUN_WATCH" = true ]; then
    run_build "$WATCH_LOG" "$LOGS_DIR/watch.status" \
        xcodebuild build \
        -project "$PROJECT" \
        -scheme "Habitual Watch" \
        -destination "platform=watchOS Simulator,id=$WATCH_SIM" \
        -configuration Debug \
        -allowProvisioningUpdates \
        -derivedDataPath "$DERIVED_DATA_WATCH" &
    WATCH_BUILD_PID=$!
    ALL_PIDS="$ALL_PIDS $WATCH_BUILD_PID"
    BUILD_PIDS="$BUILD_PIDS $WATCH_BUILD_PID"
    BUILD_SPINNER_TARGETS="${BUILD_SPINNER_TARGETS:+$BUILD_SPINNER_TARGETS, }Watch"
fi

# Wait for all builds with a spinner
gum spin --spinner dot --title "Building ${BUILD_SPINNER_TARGETS} targets..." -- bash -c "
    for pid in $BUILD_PIDS; do
        while kill -0 \$pid 2>/dev/null; do sleep 1; done
    done
"
# Ensure all builds are fully done
for pid in $BUILD_PIDS; do
    wait "$pid" 2>/dev/null || true
done

# ── Report build results ─────────────────────────────────────────────────────

echo ""
FAILED=false

report_build() {
    local label="$1"
    local status_file="$2"
    local logfile="$3"
    local status
    status=$(cat "$status_file" 2>/dev/null || echo "fail")

    if [ "$status" = "ok" ]; then
        gum style --foreground 46 "  ✅ $label built successfully"
    else
        gum style --foreground 196 "  ❌ $label build failed"
        FAILED=true
        echo ""
        grep -iE '(error:|fatal error|linker command failed)' "$logfile" 2>/dev/null \
            | grep -v "BUILD FAILED\|=== BUILD\|GenerateDSYMFile\|CompileC\|^Ld " \
            | head -20 \
            | while IFS= read -r line; do
                printf "  ${COLOR_ERR}%s${COLOR_RESET}\n" "$line"
            done
        echo ""
        gum style --foreground 245 "  Full log: $logfile"
    fi
}

[ "$RUN_MAC" = true ]   && report_build "Mac Catalyst"    "$LOGS_DIR/mac.status"   "$MAC_LOG"
[ "$RUN_IOS" = true ]   && report_build "iOS Simulator"   "$LOGS_DIR/ios.status"   "$IOS_LOG"
[ "$RUN_WATCH" = true ] && report_build "Watch Simulator" "$LOGS_DIR/watch.status" "$WATCH_LOG"
echo ""

if [ "$FAILED" = true ]; then
    gum style --bold --foreground 196 "Some builds failed. Check logs above."
    exit 1
fi

# ── Install & launch ─────────────────────────────────────────────────────────

gum spin --spinner dot --title "Installing & launching apps..." -- bash -c "
    # Mac: find and launch the .app
    if [ '$RUN_MAC' = true ]; then
        APP_PATH=\$(find '$DERIVED_DATA_MAC/Build/Products/Debug-maccatalyst' \
            -name 'Habitual.app' -maxdepth 1 2>/dev/null | head -1)
        if [ -n \"\$APP_PATH\" ]; then
            open \"\$APP_PATH\"
        fi
    fi

    # iOS: install
    if [ '$RUN_IOS' = true ]; then
        xcrun simctl install '$IPHONE_SIM' \
            '$DERIVED_DATA_IOS/Build/Products/Debug-iphonesimulator/Habitual.app' 2>/dev/null || true
    fi

    # Watch: install
    if [ '$RUN_WATCH' = true ]; then
        xcrun simctl install '$WATCH_SIM' \
            '$DERIVED_DATA_WATCH/Build/Products/Debug-watchsimulator/Habitual Watch.app' 2>/dev/null || true
    fi
"

# Launch simulator apps
[ "$RUN_IOS" = true ]   && xcrun simctl launch "$IPHONE_SIM" "com.habitual-helper.app" > /dev/null 2>&1 || true
[ "$RUN_WATCH" = true ] && xcrun simctl launch "$WATCH_SIM" "com.habitual-helper.app.watchkitapp" > /dev/null 2>&1 || true

gum style --bold --foreground 46 "All apps launched!"
echo ""
gum style --foreground 245 "Streaming runtime logs... (Ctrl-C to stop)"
echo ""

# ── Stream runtime logs ──────────────────────────────────────────────────────

if [ "$RUN_MAC" = true ]; then
    # Mac: stream via `log stream`
    log stream \
        --predicate 'subsystem == "com.habitual-helper.app" OR process == "Habitual"' \
        --style compact 2>/dev/null \
        | stream_logs "mac" "$COLOR_MAC" &
    ALL_PIDS="$ALL_PIDS $!"
fi

if [ "$RUN_IOS" = true ]; then
    # iOS: stream via simctl spawn
    xcrun simctl spawn "$IPHONE_SIM" log stream \
        --predicate 'subsystem == "com.habitual-helper.app" OR process == "Habitual"' \
        --style compact 2>/dev/null \
        | stream_logs "ios" "$COLOR_IOS" &
    ALL_PIDS="$ALL_PIDS $!"
fi

if [ "$RUN_WATCH" = true ]; then
    # Watch: stream via simctl spawn
    xcrun simctl spawn "$WATCH_SIM" log stream \
        --predicate 'subsystem == "com.habitual-helper.app" OR process CONTAINS "Habitual"' \
        --style compact 2>/dev/null \
        | stream_logs "watch" "$COLOR_WATCH" &
    ALL_PIDS="$ALL_PIDS $!"
fi

# Wait forever (until Ctrl-C)
wait

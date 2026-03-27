.PHONY: lint lint-fix format format-check test test-snapshot test-snapshot-record test-all build build-ios build-mac bump release release-ios release-mac run help

# ── Linting ──────────────────────────────────────────────────────────────────

lint:
	swiftlint lint --strict

lint-fix:
	swiftlint lint --fix && swiftlint lint --strict

# ── Formatting ───────────────────────────────────────────────────────────────

format:
	swift-format format --recursive --in-place \
		Habitual/Sources \
		HabitualWatch/Sources \
		HabitualWidgets/Sources \
		Tests

format-check:
	swift-format lint --recursive \
		Habitual/Sources \
		HabitualWatch/Sources \
		HabitualWidgets/Sources \
		Tests

# ── Testing ──────────────────────────────────────────────────────────────────

test:
	set -o pipefail && swift test --filter HabitualTests --parallel 2>&1 | tee test-output.txt

test-snapshot:
	set -o pipefail && swift test --filter HabitualSnapshotTests 2>&1 | tee snapshot-output.txt

test-snapshot-record:
	SNAPSHOT_RECORD=true swift test --filter HabitualSnapshotTests

test-all: test test-snapshot

# ── Build ────────────────────────────────────────────────────────────────────

XCODEBUILD_FLAGS = \
	-project Habitual.xcodeproj \
	-scheme Habitual \
	-configuration Debug \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGNING_ALLOWED=NO \
	ONLY_ACTIVE_ARCH=YES \
	GCC_TREAT_WARNINGS_AS_ERRORS=YES

build: build-ios build-mac

build-ios:
	@echo "🍎 Building for iOS..."
	set -o pipefail && xcodebuild build \
		$(XCODEBUILD_FLAGS) \
		-destination "generic/platform=iOS Simulator" \
		| xcpretty

build-mac:
	@echo "🖥️  Building for Mac Catalyst..."
	set -o pipefail && xcodebuild build \
		$(XCODEBUILD_FLAGS) \
		-destination "generic/platform=macOS,variant=Mac Catalyst" \
		| xcpretty

# ── Run ─────────────────────────────────────────────────────────────────────

run:
	@./scripts/run-all.sh

# ── Release ──────────────────────────────────────────────────────────────────

bump:
	@./scripts/release.sh --bump-only

release:
	@./scripts/release.sh

release-ios:
	@./scripts/release.sh --ios-only

release-mac:
	@./scripts/release.sh --mac-only

# ── Help ─────────────────────────────────────────────────────────────────────

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Linting:"
	@echo "  lint                 Run SwiftLint (strict mode)"
	@echo "  lint-fix             Auto-fix SwiftLint violations, then lint"
	@echo ""
	@echo "Formatting:"
	@echo "  format               Format all Swift sources in-place"
	@echo "  format-check         Check formatting without modifying files"
	@echo ""
	@echo "Testing:"
	@echo "  test                 Run unit & integration tests"
	@echo "  test-snapshot        Run snapshot tests (comparison mode)"
	@echo "  test-snapshot-record Re-record snapshot golden images"
	@echo "  test-all             Run unit + snapshot tests"
	@echo ""
	@echo "Building:"
	@echo "  build                Build iOS + Mac Catalyst (warnings as errors)"
	@echo "  build-ios            Build for iOS only"
	@echo "  build-mac            Build for Mac Catalyst only"
	@echo ""
	@echo "Running:"
	@echo "  run                  Launch Mac, iPhone sim, and Watch sim in parallel"
	@echo ""
	@echo "Release:"
	@echo "  bump                 Bump build number only"
	@echo "  release              Bump + archive + upload iOS & Mac to App Store Connect"
	@echo "  release-ios          Bump + archive + upload iOS only"
	@echo "  release-mac          Bump + archive + upload Mac Catalyst only"

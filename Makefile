.PHONY: lint lint-fix format format-check test test-snapshot test-snapshot-record test-all build help

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

build:
	set -o pipefail && xcodebuild build \
		-project Habitual.xcodeproj \
		-scheme Habitual \
		-destination "platform=iOS Simulator,name=iPhone 16 Pro" \
		-configuration Debug \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		ONLY_ACTIVE_ARCH=YES \
		| xcpretty

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
	@echo "  build                Build for iOS Simulator (requires xcpretty)"

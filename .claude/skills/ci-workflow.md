# Skill: CI Pipeline — Tests & Visual Regression

## Pipeline Structure

The CI runs three parallel jobs, gated by a final status check:

```
unit-tests ──────┐
snapshot-tests ──┼── ci-pass (gate)
build-check ─────┘
```

### Job: Unit & Integration Tests
- **Runner**: `macos-14`
- **Command**: `swift test --filter HabitualTests --parallel`
- Uses SPM (not Xcode) for test execution
- Caches `.build` and SPM package caches

### Job: Visual Regression Tests
- **Runner**: `macos-14`
- **Command**: `swift test --filter HabitualSnapshotTests`
- Two-phase approach on PRs:
  1. **Compare** — run tests normally; if they fail on a PR, continue to step 2
  2. **Re-record** — run with `SNAPSHOT_RECORD=true`, commit updated golden images back to the PR branch
- On `main` pushes: compare only (failures are hard failures)
- Requires `contents: write` permission for auto-committing snapshots

### Job: Build Check
- **Command**: `xcodebuild build` with code signing disabled
- Validates the Xcode project compiles for iOS Simulator
- Uses `xcpretty` for readable output
- Flags: `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`

### Job: CI Pass (Status Gate)
- Runs on `ubuntu-latest` (cheap)
- Uses `if: always()` to run even if upstream jobs fail
- Checks all three job results — any failure = overall failure
- This is the single required status check for branch protection

## Snapshot Auto-Recording Flow

On PRs, when snapshots fail:

1. First run compares against existing golden images
2. If comparison fails, `continue-on-error: true` lets the job proceed
3. Second run with `SNAPSHOT_RECORD=true` re-records all snapshots
4. Changed `.png` files are committed with `github-actions[bot]` author
5. The commit message includes `[ci]` tag: `chore: update VRT golden images [ci]`
6. The push triggers a new CI run to verify the updated snapshots pass

### Safety Check

After re-recording, the workflow verifies that image files actually changed:
```bash
if git diff --cached --quiet; then
    echo "Snapshot tests failed but no image files changed."
    echo "This likely indicates a test infrastructure issue, not a visual diff."
    exit 1
fi
```

This prevents silent false-passes where tests fail for non-visual reasons (build errors, missing dependencies, etc.).

## Common Pitfalls

1. **`continue-on-error` without re-record step** — Snapshot failures silently pass; always pair with auto-recording
2. **Missing `fetch-depth: 0`** — Needed for git operations (comparing, pushing commits)
3. **Missing `ref: ${{ github.head_ref }}`** — Without this, PR checkouts are in detached HEAD; can't push back
4. **Missing `contents: write` permission** — Auto-commit fails silently
5. **Caching `.build` directory** — SPM packages and build artifacts; key on `Package.resolved` hash
6. **Xcode version selection** — Use fallback chain (`15.3` → latest `15.x` → any) since runner images vary

## Adding New Test Targets

When adding a new test target:
1. Add it to `Package.swift` as a `.testTarget`
2. Add a corresponding `--filter` job in `ci.yml` (or add to existing filter)
3. If it needs snapshot infrastructure, depend on `SnapshotTesting` package and subclass `SnapshotTestCase`

## Running CI Checks Locally

```bash
# Reproduce unit test job
swift test --filter HabitualTests --parallel

# Reproduce snapshot test job (compare)
swift test --filter HabitualSnapshotTests

# Reproduce snapshot test job (record)
SNAPSHOT_RECORD=true swift test --filter HabitualSnapshotTests

# Reproduce build check job
xcodebuild build \
    -project Habitual.xcodeproj \
    -scheme Habitual \
    -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
    -configuration Debug \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

#!/bin/bash
set -euo pipefail

# ci_post_clone.sh — Runs after Xcode Cloud clones the repository.
# Use this for any dependency installation or environment setup.

echo "--- Post-clone setup ---"

# Print Xcode Cloud environment info
echo "CI_BUILD_NUMBER: ${CI_BUILD_NUMBER:-not set}"
echo "CI_BRANCH: ${CI_BRANCH:-not set}"
echo "CI_TAG: ${CI_TAG:-not set}"
echo "CI_XCODEBUILD_ACTION: ${CI_XCODEBUILD_ACTION:-not set}"

# Install any Homebrew dependencies if needed
# (Uncomment if your project requires additional tools)
# brew install swiftlint

echo "--- Post-clone setup complete ---"

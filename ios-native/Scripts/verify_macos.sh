#!/bin/zsh

set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)

cd "$repo_dir"

echo "==> swift test"
swift test

echo "==> xcodebuild macOS"
xcodebuild \
  -workspace TaigiDictNative.xcworkspace \
  -scheme TaigiDictNativeMac \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

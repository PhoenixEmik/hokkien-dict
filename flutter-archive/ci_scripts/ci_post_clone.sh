#!/bin/sh

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_ROOT="$HOME/flutter"
METADATA_FILE="$REPO_ROOT/.metadata"

FLUTTER_CHANNEL="$(awk -F'"' '/channel:/ {print $2; exit}' "$METADATA_FILE")"
FLUTTER_REVISION="$(awk -F'"' '/revision:/ {print $2; exit}' "$METADATA_FILE")"

if [ -z "$FLUTTER_CHANNEL" ] || [ -z "$FLUTTER_REVISION" ]; then
  echo "Failed to read Flutter channel/revision from $METADATA_FILE" >&2
  exit 1
fi

if [ ! -d "$FLUTTER_ROOT" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_CHANNEL" "$FLUTTER_ROOT"
fi

git -C "$FLUTTER_ROOT" fetch --depth 1 origin "$FLUTTER_REVISION"
git -C "$FLUTTER_ROOT" checkout "$FLUTTER_REVISION"

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter config --no-analytics
flutter precache --ios

cd "$REPO_ROOT"
flutter pub get

cd "$REPO_ROOT/ios"
pod install

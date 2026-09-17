#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: AppStoreScreenshots/capture-current-simulator.sh iphone69 home"
  echo "Usage: AppStoreScreenshots/capture-current-simulator.sh ipad13 settings"
  exit 1
fi

DEVICE="$1"
SLUG="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/captures/$DEVICE"
OUTPUT_PATH="$OUTPUT_DIR/$SLUG.png"

mkdir -p "$OUTPUT_DIR"
xcrun simctl io booted screenshot "$OUTPUT_PATH"

echo "Saved simulator screenshot: $OUTPUT_PATH"

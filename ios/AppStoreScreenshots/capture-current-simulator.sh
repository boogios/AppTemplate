#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: AppStoreScreenshots/capture-current-simulator.sh iphone63 home en-US"
  echo "Usage: AppStoreScreenshots/capture-current-simulator.sh duoInner home ko"
  exit 1
fi

DEVICE="$1"
SLUG="$2"
LOCALE="$3"
[[ "$DEVICE" =~ ^(iphone63|iphone69|duoOuter|duoInner|ipad13)$ ]] || { echo "Unsupported device key"; exit 1; }
[[ "$SLUG" =~ ^[a-zA-Z0-9_-]+$ && "$LOCALE" =~ ^[a-zA-Z0-9-]+$ ]] || { echo "Invalid card/locale"; exit 1; }
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/captures/$DEVICE/$LOCALE"
OUTPUT_PATH="$OUTPUT_DIR/$SLUG.png"

mkdir -p "$OUTPUT_DIR"
if [[ "$DEVICE" == duo* && -z "${SIMULATOR_DISPLAY:-}" ]]; then
  echo "For Duo, set SIMULATOR_DISPLAY from: xcrun simctl io <udid> enumerate"
  echo "Choose the actual outer/inner display UUID; the default may select the outer display."
  exit 1
fi
if [ -n "${SIMULATOR_DISPLAY:-}" ]; then
  xcrun simctl io "${SIMULATOR_UDID:-booted}" screenshot --display="$SIMULATOR_DISPLAY" "$OUTPUT_PATH"
else
  xcrun simctl io "${SIMULATOR_UDID:-booted}" screenshot "$OUTPUT_PATH"
fi
python3 - "$OUTPUT_PATH" "$DEVICE" <<'PY'
import sys
from PIL import Image
path, device = sys.argv[1:]
with Image.open(path) as image:
    ratio = min(image.size) / max(image.size)
expected = {'duoOuter': 1398/2034, 'duoInner': 2007/2853}
if device in expected and abs(ratio - expected[device]) > .01:
    raise SystemExit('Wrong Duo posture/aspect ratio; do not submit this capture')
PY

echo "Saved simulator screenshot: $OUTPUT_PATH"
echo "Verify the app is visibly in $LOCALE before using this capture in an export."

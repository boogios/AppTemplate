#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: ./scripts/new-android-app.sh AppName com.example.app [DisplayName]"
  exit 1
fi

APP_NAME="$1"
APPLICATION_ID="$2"
DISPLAY_NAME="${3:-${DISPLAY_NAME:-$APP_NAME}}"

if [[ ! "$APP_NAME" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
  echo "AppName must be a Kotlin-safe identifier: letters, numbers, and underscores."
  exit 1
fi

if [[ ! "$APPLICATION_ID" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]]; then
  echo "Application id must look like com.example.app"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${BOOGIOS_WORKSPACE_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TEMPLATE_DIR="${BOOGIOS_ANDROID_TEMPLATE_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)/android}"
DEST_DIR="$WORKSPACE_DIR/$APP_NAME-Android"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Android template directory not found: $TEMPLATE_DIR"
  exit 1
fi

if [ -e "$DEST_DIR" ]; then
  echo "Destination already exists: $DEST_DIR"
  exit 1
fi

exec python3 "$SCRIPT_DIR/native_template.py" --platform android \
  --name "$APP_NAME" --identifier "$APPLICATION_ID" --display "$DISPLAY_NAME" \
  --template "$TEMPLATE_DIR" --workspace "$WORKSPACE_DIR"

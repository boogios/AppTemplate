#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
  echo "Usage: ./scripts/new-ios-app.sh AppName com.example.app [DisplayName] [AppStoreCategory]"
  exit 1
fi

APP_NAME="$1"
BUNDLE_ID="$2"
APP_PACKAGE_NAME="$(printf '%s-ios' "$APP_NAME" | tr '[:upper:]_' '[:lower:]-')"
DISPLAY_NAME="${3:-${DISPLAY_NAME:-}}"
APP_CATEGORY="${4:-${APP_STORE_PRIMARY_CATEGORY:-}}"

APP_STORE_CATEGORIES=(
  "Books"
  "Business"
  "Developer Tools"
  "Education"
  "Entertainment"
  "Finance"
  "Food & Drink"
  "Games"
  "Graphics & Design"
  "Health & Fitness"
  "Lifestyle"
  "Magazines & Newspapers"
  "Medical"
  "Music"
  "Navigation"
  "News"
  "Photo & Video"
  "Productivity"
  "Reference"
  "Shopping"
  "Social Networking"
  "Sports"
  "Travel"
  "Utilities"
  "Weather"
)

if [[ ! "$APP_NAME" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
  echo "AppName must be a Swift-safe identifier: letters, numbers, underscores, and cannot start with a number."
  exit 1
fi

if [[ ! "$BUNDLE_ID" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z]{2,}[A-Za-z0-9.-]*$ ]]; then
  echo "Bundle id must look like com.example.app"
  exit 1
fi

if [ -z "$DISPLAY_NAME" ]; then
  if [ -t 0 ]; then
    read -r -p "Display name [$APP_NAME]: " DISPLAY_NAME
    DISPLAY_NAME="${DISPLAY_NAME:-$APP_NAME}"
  else
    DISPLAY_NAME="$APP_NAME"
  fi
fi

category_is_valid() {
  local candidate="$1"
  local category
  for category in "${APP_STORE_CATEGORIES[@]}"; do
    if [ "$category" = "$candidate" ]; then
      return 0
    fi
  done
  return 1
}

if [ -z "$APP_CATEGORY" ]; then
  if [ -t 0 ]; then
    echo "Choose App Store category:"
    select category in "${APP_STORE_CATEGORIES[@]}"; do
      if [ -n "${category:-}" ]; then
        APP_CATEGORY="$category"
        break
      fi
      echo "Invalid category. Choose a number from the list."
    done
  else
    APP_CATEGORY="Utilities"
  fi
fi

if ! category_is_valid "$APP_CATEGORY"; then
  echo "Invalid App Store category: $APP_CATEGORY"
  echo "Valid categories:"
  printf ' - %s\n' "${APP_STORE_CATEGORIES[@]}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="${BOOGIOS_WORKSPACE_DIR:-$DEFAULT_WORKSPACE_DIR}"
TEMPLATE_DIR="${BOOGIOS_TEMPLATE_DIR:-$DEFAULT_WORKSPACE_DIR/ios}"
DEST_DIR="$WORKSPACE_DIR/$APP_NAME"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Template directory not found: $TEMPLATE_DIR"
  exit 1
fi

if [ -e "$DEST_DIR" ]; then
  echo "Destination already exists: $DEST_DIR"
  exit 1
fi

command -v xcodegen >/dev/null 2>&1 || {
  echo "xcodegen is required. Install it before creating a new app."
  exit 1
}

exec python3 "$SCRIPT_DIR/native_template.py" --platform ios \
  --name "$APP_NAME" --identifier "$BUNDLE_ID" --display "$DISPLAY_NAME" \
  --category "$APP_CATEGORY" --template "$TEMPLATE_DIR" --workspace "$WORKSPACE_DIR"

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
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="${BOOGIOS_WORKSPACE_DIR:-$(cd "$REPO_DIR/.." && pwd)}"
TEMPLATE_DIR="${BOOGIOS_ANDROID_TEMPLATE_DIR:-$REPO_DIR/android}"
DEST_DIR="$WORKSPACE_DIR/$APP_NAME-Android"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Android template directory not found: $TEMPLATE_DIR"
  exit 1
fi

if [ -e "$DEST_DIR" ]; then
  echo "Destination already exists: $DEST_DIR"
  exit 1
fi

rsync -a \
  --exclude '.DS_Store' \
  --exclude '.gradle' \
  --exclude 'build' \
  --exclude '*/build' \
  --exclude 'local.properties' \
  --exclude '.idea' \
  --exclude 'fastlane/.env' \
  "$TEMPLATE_DIR/" "$DEST_DIR/"

OLD_PACKAGE_PATH="$DEST_DIR/app/src/main/java/com/boogios/template"
PACKAGE_PATH="${APPLICATION_ID//.//}"
mkdir -p "$DEST_DIR/app/src/main/java/$PACKAGE_PATH"
find "$OLD_PACKAGE_PATH" -type f -print0 | while IFS= read -r -d '' file; do
  relative="${file#"$OLD_PACKAGE_PATH/"}"
  mkdir -p "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/$(dirname "$relative")"
  mv "$file" "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/$relative"
done
find "$DEST_DIR/app/src/main/java/com/boogios" -type d -empty -delete 2>/dev/null || true

for test_source_root in "$DEST_DIR/app/src/test/java" "$DEST_DIR/app/src/androidTest/java"; do
  old_test_package_path="$test_source_root/com/boogios/template"
  if [ -d "$old_test_package_path" ]; then
    new_test_package_path="$test_source_root/$PACKAGE_PATH"
    mkdir -p "$new_test_package_path"
    find "$old_test_package_path" -type f -print0 | while IFS= read -r -d '' file; do
      relative="${file#"$old_test_package_path/"}"
      mkdir -p "$new_test_package_path/$(dirname "$relative")"
      mv "$file" "$new_test_package_path/$relative"
    done
    find "$test_source_root/com/boogios" -type d -empty -delete 2>/dev/null || true
  fi
done

find "$DEST_DIR" -type f \( \
  -name '*.kt' -o \
  -name '*.kts' -o \
  -name '*.xml' -o \
  -name '*.md' -o \
  -name '*.pro' -o \
  -name 'Fastfile' -o \
  -name 'Appfile' -o \
  -name '.env.example' \
\) -print0 | while IFS= read -r -d '' file; do
  APP_NAME="$APP_NAME" APPLICATION_ID="$APPLICATION_ID" perl -0pi -e '
    s/AppTemplateAndroid/$ENV{APP_NAME}/g;
    s/com\.boogios\.template/$ENV{APPLICATION_ID}/g;
  ' "$file"
done

find "$DEST_DIR/app/src/main/res" -path '*/strings.xml' -print0 | while IFS= read -r -d '' file; do
  APP_DISPLAY_NAME="$DISPLAY_NAME" perl -0pi -e '
    my $display = $ENV{APP_DISPLAY_NAME};
    $display =~ s/\\/\\\\/g;
    $display =~ s/"/\\"/g;
    s#<string name="app_name">[^<]*</string>#<string name="app_name">$display</string>#g;
  ' "$file"
done

cp "$DEST_DIR/local.properties.example" "$DEST_DIR/local.properties"

if [ ! -f "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/data/settings/OnboardingStore.kt" ]; then
  echo "Missing onboarding store: $DEST_DIR/app/src/main/java/$PACKAGE_PATH/data/settings/OnboardingStore.kt"
  exit 1
fi

if [ ! -f "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/features/onboarding/OnboardingScreen.kt" ]; then
  echo "Missing onboarding screen: $DEST_DIR/app/src/main/java/$PACKAGE_PATH/features/onboarding/OnboardingScreen.kt"
  exit 1
fi

if [ ! -f "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/data/premium/PremiumStore.kt" ] || [ ! -f "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/features/premium/PremiumPaywallDialog.kt" ]; then
  echo "Missing premium template files"
  exit 1
fi

if ! rg -q 'premium\.monthly' "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/core/config/AppConfig.kt"; then
  echo "Missing premium product IDs"
  exit 1
fi

if [ ! -f "$DEST_DIR/app/src/main/java/$PACKAGE_PATH/core/review/InAppReviewManager.kt" ]; then
  echo "Missing app review manager"
  exit 1
fi

if ! rg -q 'com\.google\.android\.play:review:2\.0\.2' "$DEST_DIR/app/build.gradle.kts" || ! rg -q 'com\.google\.android\.play:review-ktx:2\.0\.2' "$DEST_DIR/app/build.gradle.kts"; then
  echo "Missing Google Play in-app review dependency"
  exit 1
fi

if ! rg -q 'android.permission.POST_NOTIFICATIONS' "$DEST_DIR/app/src/main/AndroidManifest.xml"; then
  echo "Missing Android notification permission declaration"
  exit 1
fi

echo "Created $APP_NAME Android app at $DEST_DIR"
echo "Application id: $APPLICATION_ID"
echo "Display name: $DISPLAY_NAME"

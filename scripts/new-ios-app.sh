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
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_WORKSPACE_DIR="$(cd "$REPO_DIR/.." && pwd)"
WORKSPACE_DIR="${BOOGIOS_WORKSPACE_DIR:-$DEFAULT_WORKSPACE_DIR}"
TEMPLATE_DIR="${BOOGIOS_TEMPLATE_DIR:-$REPO_DIR/ios}"
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

rsync -a \
  --exclude '.DS_Store' \
  --exclude '.bundle' \
  --exclude '.build' \
  --exclude 'build' \
  --exclude 'DerivedData' \
  --exclude 'node_modules' \
  --exclude 'vendor' \
  --exclude 'artifacts' \
  --exclude 'outputs' \
  --exclude 'fastlane/.env' \
  --exclude 'fastlane/report.xml' \
  --exclude 'Configs/AppSecrets.xcconfig' \
  --exclude '*.xcodeproj' \
  "$TEMPLATE_DIR/" "$DEST_DIR/"

cp "$DEST_DIR/Configs/AppSecrets.xcconfig.example" "$DEST_DIR/Configs/AppSecrets.xcconfig"

mv "$DEST_DIR/AppTemplate" "$DEST_DIR/$APP_NAME"
mv "$DEST_DIR/$APP_NAME/AppTemplateApp.swift" "$DEST_DIR/$APP_NAME/${APP_NAME}App.swift"
mv "$DEST_DIR/AppTemplateTests" "$DEST_DIR/${APP_NAME}Tests"
mv "$DEST_DIR/${APP_NAME}Tests/AppTemplateArchitectureTests.swift" "$DEST_DIR/${APP_NAME}Tests/${APP_NAME}ArchitectureTests.swift"
mv "$DEST_DIR/AppTemplateUITests" "$DEST_DIR/${APP_NAME}UITests"
mv "$DEST_DIR/${APP_NAME}UITests/AppTemplateSmokeUITests.swift" "$DEST_DIR/${APP_NAME}UITests/${APP_NAME}SmokeUITests.swift"

find "$DEST_DIR" -type f \( \
  -name "*.swift" -o \
  -name "*.yml" -o \
  -name "*.yaml" -o \
  -name "*.plist" -o \
  -name "*.xcconfig" -o \
  -name "*.strings" -o \
  -name "*.json" -o \
  -name "*.html" -o \
  -name "*.mjs" -o \
  -name "*.sh" -o \
  -name "*.md" -o \
  -name "package.json" -o \
  -name "package-lock.json" -o \
  -name "Fastfile" -o \
  -name "Appfile" -o \
  -name "Gemfile" -o \
  -name ".env.example" -o \
  -name ".gitignore" \
\) -print0 | while IFS= read -r -d '' file; do
  APP_NAME="$APP_NAME" APP_PACKAGE_NAME="$APP_PACKAGE_NAME" BUNDLE_ID="$BUNDLE_ID" perl -0pi -e 's/AppTemplate/$ENV{APP_NAME}/g; s/apptemplate-ios/$ENV{APP_PACKAGE_NAME}/g; s/com\.boogios\.template/$ENV{BUNDLE_ID}/g' "$file"
done

APP_DISPLAY_NAME="$DISPLAY_NAME" perl -0pi -e '
  my $display = $ENV{APP_DISPLAY_NAME};
  $display =~ s/\\/\\\\/g;
  $display =~ s/"/\\"/g;
  s/(<key>CFBundleDisplayName<\/key>\s*<string>)[^<]*(<\/string>)/$1$display$2/g;
' "$DEST_DIR/$APP_NAME/Info.plist"

find "$DEST_DIR/$APP_NAME/Global/Localizing" -name "InfoPlist.strings" -print0 | while IFS= read -r -d '' file; do
  APP_DISPLAY_NAME="$DISPLAY_NAME" perl -0pi -e '
    my $display = $ENV{APP_DISPLAY_NAME};
    $display =~ s/\\/\\\\/g;
    $display =~ s/"/\\"/g;
    s/"CFBundleDisplayName"\s*=\s*"[^"]*";/"CFBundleDisplayName" = "$display";/g;
  ' "$file"
done

APP_DISPLAY_NAME="$DISPLAY_NAME" perl -0pi -e '
  my $display = $ENV{APP_DISPLAY_NAME};
  $display =~ s/\\/\\\\/g;
  $display =~ s/"/\\"/g;
  s/static let appName = "[^"]*"/static let appName = "$display"/g;
  s/"appName":\s*"[^"]*"/"appName": "$display"/g;
  s/^APP_STORE_NAME=.*/APP_STORE_NAME=$display/mg;
' "$DEST_DIR/$APP_NAME/Global/Config.swift" "$DEST_DIR/AppStoreScreenshots/screenshot.config.json" "$DEST_DIR/fastlane/.env.example"

APP_CATEGORY="$APP_CATEGORY" perl -0pi -e '
  my $category = $ENV{APP_CATEGORY};
  $category =~ s/\\/\\\\/g;
  s/^APP_STORE_PRIMARY_CATEGORY=.*/APP_STORE_PRIMARY_CATEGORY=$category/mg;
' "$DEST_DIR/fastlane/.env.example"

(
  cd "$DEST_DIR"
  xcodegen generate
)

for locale in ko ja en-US en-GB en-CA en-AU de-DE fr-FR pt-BR vi; do
  if [ ! -f "$DEST_DIR/$APP_NAME/Global/Localizing/$locale.lproj/InfoPlist.strings" ]; then
    echo "Missing localization file: $APP_NAME/Global/Localizing/$locale.lproj/InfoPlist.strings"
    exit 1
  fi
done

for file in AppLanguage.swift L10n.swift CommonL10n.swift HomeL10n.swift MyPageL10n.swift; do
  if [ ! -f "$DEST_DIR/$APP_NAME/Global/Localization/$file" ]; then
    echo "Missing localization helper: $APP_NAME/Global/Localization/$file"
    exit 1
  fi
done

for file in OnboardingL10n.swift; do
  if [ ! -f "$DEST_DIR/$APP_NAME/Global/Localization/$file" ]; then
    echo "Missing onboarding localization helper: $APP_NAME/Global/Localization/$file"
    exit 1
  fi
done

for file in OnboardingStore.swift; do
  if [ ! -f "$DEST_DIR/$APP_NAME/Store/$file" ]; then
    echo "Missing onboarding store: $APP_NAME/Store/$file"
    exit 1
  fi
done

if [ ! -f "$DEST_DIR/$APP_NAME/View/Onboarding/OnboardingView.swift" ]; then
  echo "Missing onboarding view: $APP_NAME/View/Onboarding/OnboardingView.swift"
  exit 1
fi

if [ ! -f "$DEST_DIR/$APP_NAME/Store/PremiumStore.swift" ] || [ ! -f "$DEST_DIR/$APP_NAME/View/Premium/PremiumPaywallView.swift" ]; then
  echo "Missing premium template files"
  exit 1
fi

if ! rg -q 'premium\.monthly' "$DEST_DIR/$APP_NAME/Global/Config.swift"; then
  echo "Missing premium product IDs"
  exit 1
fi

if [ ! -f "$DEST_DIR/$APP_NAME/Global/Managers/AppReviewRequester.swift" ]; then
  echo "Missing app review requester: $APP_NAME/Global/Managers/AppReviewRequester.swift"
  exit 1
fi

for file in BannerAdView.swift RewardedAdSheetView.swift NativeAdLoader.swift NativeAdView.swift; do
  if [ ! -f "$DEST_DIR/$APP_NAME/View/Common/AdMob/$file" ]; then
    echo "Missing AdMob component: $APP_NAME/View/Common/AdMob/$file"
    exit 1
  fi
done

for file in screenshot.config.json template.html render.mjs font-manifest.json capture-current-simulator.sh; do
  if [ ! -f "$DEST_DIR/AppStoreScreenshots/$file" ]; then
    echo "Missing App Store screenshot tool: AppStoreScreenshots/$file"
    exit 1
  fi
done

if [ ! -f "$DEST_DIR/package.json" ]; then
  echo "Missing screenshot package config: package.json"
  exit 1
fi

echo "Created $APP_NAME at $DEST_DIR"
echo "Display name: $DISPLAY_NAME"
echo "App Store category: $APP_CATEGORY"
echo "Open: $DEST_DIR/$APP_NAME.xcodeproj"

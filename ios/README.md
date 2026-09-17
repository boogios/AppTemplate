# AppTemplate

Boogios-style SwiftUI starter app for the Boogios workspace.

## Create A New App

From the workspace root:

```sh
./scripts/new-ios-app.sh MyNewApp com.example.mynewapp
```

The script copies this template, replaces project/app identifiers, and runs
`xcodegen generate` in the new app directory. In an interactive terminal it also
asks for the app display name and App Store category. In automation you can pass
them explicitly:

```sh
./scripts/new-ios-app.sh MyNewApp com.example.mynewapp "My New App" Utilities
```

For isolated generator verification, set `BOOGIOS_WORKSPACE_DIR` to a temporary directory. The source template remains the workspace `AppTemplate` unless `BOOGIOS_TEMPLATE_DIR` is also provided.

## Architecture

The template uses a small SwiftUI starter structure that can grow into a
feature-oriented app without requiring an early rewrite.

```text
AppTemplate/
├── AppTemplate/
│   ├── Global/
│   │   ├── Config.swift                 # App identity, URLs, product IDs
│   │   ├── Enums/                       # Tabs and app-wide themes
│   │   ├── Extension/                   # Color, font, view modifiers
│   │   ├── Localization/                # AppLanguage, L10n, feature copy
│   │   ├── Localizing/                  # InfoPlist.strings per locale
│   │   ├── Managers/                    # App lifecycle and SDK adapters
│   │   └── Resource/                    # Pretendard fonts and shared assets
│   ├── Store/
│   │   ├── AppStore.swift               # Starter app state
│   │   ├── SettingsStore.swift          # Theme and language preferences
│   │   ├── OnboardingStore.swift        # First-run state and nickname
│   │   └── PremiumStore.swift           # StoreKit products and entitlements
│   ├── View/
│   │   ├── Common/                      # Reusable controls, web, ads
│   │   ├── Home/                        # Default Home tab
│   │   ├── MyPage/                      # Default Settings tab
│   │   ├── Onboarding/                  # First-run flow
│   │   └── Premium/                     # Paywall UI
│   ├── Model/                           # Product data models
│   ├── Infrastructure/                  # Product service adapters
│   └── AppTemplateApp.swift             # Environment and lifecycle root
├── AppTemplateTests/                    # Unit and architecture tests
├── AppTemplateUITests/                  # UI smoke tests
├── Configs/                             # Safe config example and local config
├── AppStoreScreenshots/                 # Localized screenshot tooling
├── fastlane/                            # TestFlight and App Store lanes
├── project.yml                          # XcodeGen source of truth
├── DESIGN.md                            # UI implementation checklist
└── AGENTS.md                            # Template maintenance rules
```

`View/` contains the starter screens. Once a product feature becomes large or
has several independent sheets, move it to `Features/<Feature>/` and keep its
screen, view model, repository, and feature-local components together. Keep
state ownership in the parent feature view during a structural split.

`Global/Managers/` contains adapters for system and SDK services. Feature code
should call these through a store or dependency boundary instead of creating
SDK singletons directly. `DESIGN.md` defines visual rules, while `AGENTS.md`
defines structure and verification rules.

## Defaults

- iOS 18+
- iPhone-only target by default
- XcodeGen project source
- Boogios-style `EnvironmentObject` store injection
- Unit-test target with starter architecture contract tests and a UI smoke test target
- First-run onboarding with two introductions, required nickname, notification
  permission guidance, advertising privacy guidance, and introduction-only replay
- Korean, Japanese, US/UK/Canada/Australia English, German, French, Brazilian Portuguese, and Vietnamese localization resources
- Settings screen with a premium subscription card at the top, language, theme, conditional privacy choices, developer apps, app review, support, terms, privacy, and version
- StoreKit 2 premium paywall with monthly, yearly, and lifetime product ID placeholders, purchase, entitlement refresh, and restore flow
- System App Store review request from Settings; Apple controls the review sheet frequency and visibility
- AdMob with UMP consent gating, Mixpanel, and Supabase setup values with placeholder keys
- iOS notification permission, UMP, and ATT requests are conditional on OS state
  and real AdMob configuration; declined permissions never block entry
- Automatic signing with Boogios development team `MAZQ6JDBT4`
- Fastlane TestFlight and App Store release lanes based on ReDay and Janjan

## Default User Flows

### First launch

`LaunchView` checks `OnboardingStore`. On the first launch it presents:

1. Two product introduction pages
2. A required nickname field, trimmed and validated to 1-20 characters
3. Notification permission guidance and a conditional system request
4. Advertising privacy guidance with conditional UMP and ATT requests
5. The Home tab

Permission denial never blocks app entry. Placeholder AdMob configuration skips
UMP and ATT. Completing onboarding stores the state locally. When Mixpanel is
configured, the nickname is saved as `$name` and the completion event is sent.

The Settings menu can replay only the two introduction pages. It keeps the
nickname and never forces the permission steps again.

### Settings

`MyPageView` is the required Settings tab. The default layout is:

1. Premium subscription card
2. Language, theme, and conditional privacy choices
3. Onboarding replay, developer apps, review request, support, terms, and
   privacy links
4. App version

The developer-apps entry opens `AppConfig.developerAppsURL`. The review entry
uses Apple's system review request API. No custom rating dialog is included.

### Premium

`PremiumStore` owns StoreKit 2 product loading, purchases, restore purchases,
transaction updates, and entitlement refresh. `PremiumPaywallView` displays
monthly, yearly, and lifetime product choices when App Store Connect products
are available. Placeholder IDs show an unavailable/setup state instead of a
fake price.

## Required Settings Tab

Every generated app must keep the Settings tab. Product-specific work may add
tabs or screens, but `MainView` should still include `MyPageView()` tagged as
`AppTab.myPage`, and the app entry point should keep injecting `SettingsStore`.
Keep the language, theme, developer apps, support, terms, privacy, and app
version settings unless the user explicitly asks to remove one.

## Required Localization

Every generated app must keep `ko`, `ja`, `en-US`, `en-GB`, `en-CA`, `en-AU`,
`de-DE`, `fr-FR`, `pt-BR`, and `vi` support. English (`en-US`) is the default
App Store metadata language. The
template includes:

- `Global/Localization/AppLanguage.swift`
- `Global/Localization/L10n.swift`
- Feature-level `*L10n.swift` helpers
- `Global/Localizing/*.lproj` display-name resources for every required locale

When adding new screens, add copy through a feature `L10n` helper instead of
hardcoding user-facing strings in SwiftUI views.

Onboarding copy is centralized in `Global/Localization/OnboardingL10n.swift`.
The nickname is stored locally and sent to Mixpanel as `$name` only when
Mixpanel is configured. Settings can replay the two introduction pages without
repeating nickname or permission steps.

## Design Workflow

Before creating or changing UI, read `DESIGN.md` in the app directory. It is the
local checklist for Boogios design tokens, spacing, component choices, and
screen structure. Use the workspace-level `../DESIGN.md` only for broader
principles or missing details.

## Colors

Change `AppConfig.mainColorHex` to set the app's main brand color. The template
automatically derives `Color.boogiosMainSoft` and `Color.boogiosMainSofter`
from that value. `Color.boogiosGray1` through `Color.boogiosGray10` are shared
grayscale tokens for every generated app, with dynamic light/dark values.

## Common UI

- `BoogiosNavigationButton`
- `BoogiosTextField`
- `BoogiosBackButton`
- `BoogiosToastView` with `.boogiosToast(...)`
- `BoogiosToggleStyle` and `BoogiosOutlineToggleStyle`
- `BoogiosBottomSheet`
- `BoogiosWebView` and `BoogiosWebSheetView`
- `BannerAdView`
- `NativeAdLoader` and `NativeAdCardView`
- `RewardedAdSheetView`

## SDK Keys

Copy the safe example, then edit the ignored app-local file for each generated app. The generator does this copy automatically for new apps:

```sh
cp Configs/AppSecrets.xcconfig.example Configs/AppSecrets.xcconfig
```

Configure these keys in `Configs/AppSecrets.xcconfig`:

- `ADMOB_APP_ID`
- `ADMOB_BANNER_ID`
- `ADMOB_NATIVE_ID`
- `ADMOB_REWARD_ID`
- `ADMOB_TEST_DEVICE`
- `MIXPANEL_TOKEN`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_REDIRECT_URL`

Placeholder values are safe for local builds. `AdMobManager` and
`MixpanelManager` skip initialization until real app keys are set.
The reusable AdMob views live under `View/Common/AdMob` and stay no-op until
`ADMOB_APP_ID` and the matching ad unit ID are configured. When a real AdMob
app ID is present, UMP consent is refreshed on launch, required consent forms
are shown, and the Settings screen exposes privacy choices when required.

Premium products are configured in `Global/Config.swift` through the three
`premium*ProductID` values. Replace them with products created in App Store
Connect before release. Until products exist, the paywall shows a setup
message and never displays a fake price.
Keep Supabase URLs in `.xcconfig` as `https:/$()/your-project-ref.supabase.co`
so Xcode does not treat `//` as a comment. `AppConfig` normalizes that value
back to `https://...` at runtime.

## Fastlane Release

Fastlane is preconfigured for an App Store Connect API key supplied through
`fastlane/.env`. The `.p8` file is not copied into the app; configure the local
key path or key content in your environment:

```sh
/path/to/your/AuthKey_XXXXXXXXXX.p8
```

Before releasing a generated app:

```sh
cp fastlane/.env.example fastlane/.env
bundle config set path vendor/bundle
bundle install
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bundle exec fastlane ios bootstrap_check
```

Fill app-specific values in `fastlane/.env`, especially `APP_STORE_APP_ID`,
`APP_STORE_NAME`, `APP_STORE_PRIMARY_CATEGORY`, privacy/terms URLs, App Store
copy, and TestFlight review text.

Useful lanes:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bundle exec fastlane ios build_release version:1.0.0 build_number:1
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bundle exec fastlane ios beta
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bundle exec fastlane ios release
```

## App Store Screenshots

The template includes the `screenshot-ios` localized App Store screenshot
generator under `AppStoreScreenshots/`. Each board uses a centered copy block,
a transparent capture frame matched to the real simulator image, and no
decorative background behind the capture. It includes Korean, English,
Japanese, Chinese, Thai, Vietnamese, Arabic, Hindi, Spanish, Portuguese,
French, and German font presets.

Capture the current booted simulator screen:

```sh
AppStoreScreenshots/capture-current-simulator.sh iphone69 home
AppStoreScreenshots/capture-current-simulator.sh ipad13 home
```

Edit localized copy and card order in:

```sh
AppStoreScreenshots/screenshot.config.json
```

Generate previews and export PNGs:

```sh
npm install
npm run screenshots:preview
npm run screenshots:check
npm run screenshots:release-check
npm run screenshots:export
```

New locales begin as `draft` and are preview-only until their title and body
copy has been localized. `screenshots:release-check` also requires a real
capture for every card and selected device; it blocks placeholder exports.

Exports are written to `outputs/appstore-exports/<locale>/` for `ko`, `en-US`,
and `ja`, then synced into Fastlane deliver folders with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bundle exec fastlane ios sync_app_store_screenshots
```

Set `RELEASE_SKIP_SCREENSHOTS=false` in `fastlane/.env` when screenshots should
be uploaded during the `release` lane.

# AppTemplate

Boogios-style SwiftUI starter app for the Boogios workspace.

## 처음 시작하는 분들을 위한 안내

이 폴더는 iPhone 앱을 만들기 위한 iOS 템플릿입니다. SwiftUI로 화면을 만들고,
XcodeGen으로 Xcode 프로젝트를 관리합니다. 완성된 제품이 아니라 새로운 앱의
출발점이므로, 먼저 템플릿을 그대로 실행한 다음 필요한 화면을 하나씩 바꾸는
방식으로 사용하는 것을 권장합니다.

### 준비물

- macOS
- Xcode 16 이상 권장
- iOS Simulator 또는 테스트용 iPhone
- XcodeGen: `brew install xcodegen`
- 선택 사항: Fastlane, Node.js

### 5분 안에 실행하기

저장소 루트에서 다음을 실행합니다.

```sh
cd ios
cp Configs/AppSecrets.xcconfig.example Configs/AppSecrets.xcconfig
xcodegen generate
open AppTemplate.xcodeproj
```

Xcode가 열리면 상단에서 `AppTemplate` 스킴과 iPhone Simulator를 선택하고
실행 버튼을 누릅니다. 예제 키는 placeholder이므로 광고·분석·결제는 연결되지
않지만, 홈·설정·온보딩 화면은 확인할 수 있습니다.

`AppSecrets.xcconfig`는 로컬에서만 사용하는 파일입니다. 실제 키가 없어도
템플릿을 이해하고 화면을 개발할 수 있으며, 이 파일은 Git에 커밋하지 않습니다.

### 처음 수정할 파일 순서

1. `AppTemplate/Global/Config.swift`에서 앱 이름, 브랜드 색상, URL, 상품 ID를
   확인합니다.
2. `AppTemplate/View/Home/HomeView.swift`에서 기본 홈 화면을 제품에 맞게
   바꿉니다.
3. `AppTemplate/View/MyPage/MyPageView.swift`에서 설정 화면을 확인합니다.
4. 새 문구는 `Global/Localization/`의 적절한 `*L10n.swift`에 추가합니다.
5. 화면 스타일은 `DESIGN.md`를 확인한 뒤 기존 컴포넌트와 토큰을 사용합니다.
6. 화면이 커지면 `Features/<Feature>/`로 기능을 분리합니다.

`project.yml`은 Xcode 프로젝트의 원본입니다. Xcode 프로젝트 파일을 직접
고치기보다 `project.yml`을 수정한 뒤 `xcodegen generate`를 실행해야 다음에
프로젝트를 다시 만들어도 변경사항이 유지됩니다.

## 중요한 파일부터 이해하기

처음에는 아래 순서로 보면 됩니다.

| 파일 또는 폴더 | 역할 | 초보자에게 중요한 이유 |
| --- | --- | --- |
| `AGENTS.md` | 템플릿 유지·검증 규칙 | 설정 탭, 다국어, 테스트를 실수로 지우지 않게 해줍니다. |
| `DESIGN.md` | 화면 디자인 규칙 | 색상·폰트·여백을 앱 전체에서 통일합니다. |
| `project.yml` | XcodeGen 원본 설정 | Xcode 프로젝트를 직접 수정하지 않고 여기서 관리합니다. |
| `AppTemplateApp.swift` | 앱 시작점 | Store 주입, 테마, 생명주기, SDK 초기화를 연결합니다. |
| `Global/Config.swift` | 공개 앱 설정 | 앱 이름, 브랜드 색상, URL, 상품 ID를 바꿉니다. |
| `Store/` | 상태와 저장 로직 | 온보딩·설정·구독 상태를 화면과 분리합니다. |
| `View/Home/` | 기본 홈 화면 | 제품의 첫 화면을 만들 때 시작합니다. |
| `View/MyPage/` | 기본 설정 화면 | 언어·테마·프리미엄·링크 메뉴를 관리합니다. |
| `View/Onboarding/` | 첫 실행 화면 | 소개, 닉네임, 권한 안내 흐름을 관리합니다. |
| `View/Premium/` | 구독 화면 | StoreKit 상품과 페이월 UI를 연결합니다. |
| `Global/Localization/` | 다국어 문구 | SwiftUI 코드에 문장을 직접 쓰지 않게 합니다. |
| `Global/Managers/` | 외부 SDK·시스템 연결 | 광고·분석·ATT·리뷰 요청을 한 곳에서 관리합니다. |

### 앱을 바꿀 때의 기본 순서

1. `Global/Config.swift`의 앱 이름, 색상, URL, 상품 ID를 바꿉니다.
2. `project.yml`의 앱 식별자와 버전을 확인합니다.
3. `View/Home/HomeView.swift`에서 홈 화면을 제품에 맞게 수정합니다.
4. 설정 메뉴는 `View/MyPage/SettingMenu.swift`와 `MyPageView.swift`를
   확인합니다.
5. 새 기능은 작은 경우 `View/`, 커진 기능은 `Features/<Feature>/`에 둡니다.
6. 문구는 `*L10n.swift`와 모든 로케일에 추가합니다.
7. `xcodegen generate` 후 빌드와 테스트를 실행합니다.

### iOS 키 값 관리

`Configs/AppSecrets.xcconfig.example`에는 필요한 키 이름만 안전한 예시 값으로
들어 있습니다. 다음처럼 복사한 뒤 실제 앱의 키를 입력합니다.

```sh
cp Configs/AppSecrets.xcconfig.example Configs/AppSecrets.xcconfig
```

`AppSecrets.xcconfig`에는 다음 값이 들어갑니다.

- `ADMOB_APP_ID`, `ADMOB_BANNER_ID`, `ADMOB_NATIVE_ID`, `ADMOB_REWARD_ID`
- `ADMOB_TEST_DEVICE`
- `MIXPANEL_TOKEN`
- `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_REDIRECT_URL`

이 파일은 `.gitignore`에 등록되어 있어 Git에 올리지 않습니다. 앱 이름,
브랜드 색상, 외부 URL, StoreKit 상품 ID는 비밀 키가 아니므로
`Global/Config.swift`에서 앱별로 변경합니다. 그래도 앱마다 다른 값을 사용해야
하며 다른 앱의 키를 복사하지 않습니다.

### 외부 기능이 연결되는 위치

- 광고: `Global/Managers/AdMobManager.swift`와 `View/Common/AdMob/`
- 개인정보 동의: UMP가 먼저 처리되고, iOS ATT는 광고 설정과 권한 상태에 따라
  조건부로 요청됩니다.
- 분석: `Global/Managers/MixpanelManager.swift`
- 결제: `Store/PremiumStore.swift`와 `View/Premium/PremiumPaywallView.swift`
- 리뷰: `Global/Managers/AppReviewRequester.swift`
- 알림 권한: `Global/Managers/NotificationAuthorizationManager.swift`

키가 placeholder이면 해당 기능이 실행되지 않는 것이 정상입니다. 먼저 앱의
화면 흐름을 완성한 다음 실제 키를 넣고 외부 서비스 연결을 확인하세요.

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

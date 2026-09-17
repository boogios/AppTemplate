# AppTemplate Agent Guide

This app is generated from the Boogios iOS starter template. Keep the starter
architecture intact unless the user explicitly asks to remove a template system.

## Design Source

- Read `DESIGN.md` before creating or changing SwiftUI screens.
- Treat `DESIGN.md` as the app-local implementation checklist for color,
  typography, layout, spacing, component usage, and interaction defaults.
- If a design decision is not covered locally, fall back to the workspace guide
  at `../DESIGN.md`.
- Prefer existing Boogios tokens and common components before introducing new
  visual rules.

## Required Template Surface

- Keep the Settings tab in `Global/Managers/MainView.swift`.
- Keep `AppTab.myPage`, `NavigationPathManager.myPagePath`, `SettingsStore`,
  `View/MyPage`, `Global/Localization/MyPageL10n.swift`, and
  `CommonL10n.tabSettings`.
- Product-specific app work may add tabs or screens, but it must not remove the
  settings tab or replace `MyPageView` with a dead placeholder.
- The settings tab must continue to expose language, theme, developer apps,
  support, terms, privacy, and app version entries unless the user explicitly
  narrows that scope. When AdMob is configured, UMP may add a conditional
  privacy choices entry point alongside language and theme.
- Keep app-wide theme handling at the app entry point with
  `.preferredColorScheme(settingsStore.selectedTheme.colorScheme)` so the
  default `system` theme follows iOS light/dark mode automatically.
- Keep app-level keys in `Configs/AppSecrets.xcconfig`.
- Keep AdMob requests behind UMP consent state and retain the conditional
  privacy choices entry point when AdMob is configured.
- Keep release metadata and App Store Connect settings app-local under
  `fastlane/`. Real app-specific values belong in ignored `fastlane/.env`;
  shared Boogios API key defaults may stay in `fastlane/.env.example`.
- Keep Korean, English, and Japanese localization support in every generated
  app. Do not remove `AppLanguage`, `L10n`, feature-level `*L10n` helpers, or
  `Global/Localizing/en.lproj`, `ko.lproj`, and `ja.lproj`.
- Add new user-facing screen copy through a feature-level `L10n` helper instead
  of hardcoding strings directly in SwiftUI views.

## Growth Path

- Keep the starter folders while screens are small. When one feature view grows
  beyond roughly 500 lines or contains several independent sheets/sections,
  move it to `Features/<Feature>/` and split it by screen responsibility.
- Keep state ownership in the parent feature view during a structural split;
  introduce a view model only when business state or async behavior needs an
  independently testable owner.
- Route UserDefaults, cloud sync, notifications, widgets, watch connectivity,
  review prompts, and SDK singletons through an app dependency container before
  a store becomes responsible for multiple external systems.
- Add or update unit tests for every dependency seam and retain the default live
  dependency so existing app entry points do not need special setup.

## Before Finishing App Changes

- Confirm `MainView` still contains a `MyPageView()` tab tagged as
  `AppTab.myPage`.
- Confirm the app still injects `SettingsStore` into the environment from the
  app entry point.
- Confirm the app entry point still applies the selected `AppTheme` to the root
  view.
- Confirm the app still has Korean, English, and Japanese localization helpers
  and `InfoPlist.strings` files.
- Regenerate the Xcode project with `xcodegen generate` after changing
  `project.yml`.
- For release work, run Fastlane from the app root with
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Inspect
  `fastlane/Fastfile`, `fastlane/Appfile`, and `fastlane/.env` before upload or
  App Store review submission.

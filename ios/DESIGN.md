# AppTemplate Design Guide

This template follows the workspace-level guide at `../DESIGN.md`. Use this file
as the app-local implementation checklist when creating or editing SwiftUI
screens inside an app generated from `AppTemplate`. Product-specific design
decisions belong in the generated app unless they should apply to every future
Boogios app.

## Design Principles

- Keep the interface calm, friendly, and easy to scan.
- Prefer one clear primary action per screen.
- Use cards and grouped sections to create hierarchy without unnecessary
  decoration.
- Keep text short and localizable; allow for longer translations in layouts.
- Respect Dynamic Type, VoiceOver labels, sufficient contrast, and practical
  touch targets.
- Reuse existing tokens and common components before introducing new visual
  rules.

## Provided Tokens

### Color

The app's main brand color comes from `AppConfig.mainColorHex`.

- `boogiosMain`: primary actions, selected states, active icons
- `boogiosMainSoft`: soft selected backgrounds and low-emphasis brand surfaces
- `boogiosMainSofter`: avatars, empty states, gentle brand emphasis
- `boogiosWhite`: cards and elevated surfaces
- `boogiosGray1`: default screen background
- `boogiosGray2` / `boogiosGray3`: dividers and borders
- `boogiosGray6` / `boogiosGray7`: secondary text
- `boogiosGray9`: primary text

These tokens are dynamic and must remain the default colors for common screens.
Do not hardcode fixed light-mode colors inside settings, cards, lists, or form
rows. Use adaptive foreground and surface colors when a component needs to work
in both light and dark mode.

### Typography

Use Pretendard through the existing SwiftUI tokens:

- `headline1`, `headline2`, `headline3`
- `subtitle1`, `subtitle2`, `subtitle3`
- `body1`, `body2`
- `caption1`, `caption2`

For custom sizes, use the provided helpers:

- `pretendardBold(size:)`
- `pretendardSemiBold(size:)`
- `pretendardMedium(size:)`
- `pretendardRegular(size:)`
- `pretendardLight(size:)`

Do not document or design new template screens around SF Pro or Inter.
Keep line spacing and text width generous enough for localization and Dynamic
Type.

### Spacing And Shapes

- Standard screen horizontal padding: 20pt
- Root vertical stack spacing: 16-20pt
- Standard section spacing: 16-28pt depending on hierarchy
- Card internal padding: 16-20pt
- Standard card corner radius: around 16pt
- Input and primary button corner radius: 14pt
- Practical minimum touch target: 44pt or larger

Keep these measurements consistent across Home, Settings, onboarding, and
paywall screens. Avoid adding dividers when spacing and card grouping already
communicate hierarchy.

## New Screen Defaults

Start most screens with this structure:

- `ScrollView` when content may exceed the viewport.
- Root `VStack` with 16-20pt spacing.
- Horizontal padding of 20pt.
- Background `boogiosGray1`.
- Cards or grouped sections using `boogiosWhite`, 16pt radius, and 16-20pt
  internal padding.
- Primary text in `boogiosGray9`; secondary text in `boogiosGray6` or
  `boogiosGray7`.
- `customNavigationBar(title:)` for standard navigation titles.
- Settings lists should set row backgrounds to `boogiosWhite` and the screen
  background to `boogiosGray1` so light/dark mode stays consistent.

## Common Components First

Prefer existing common views before creating new UI:

- `BoogiosNavigationButton` for full-width primary actions.
- `BoogiosTextField` for simple text input.
- `BoogiosBackButton` for custom back affordances.
- `BoogiosToastView` and `.boogiosToast(...)` for short confirmation feedback.
- `BoogiosToggleStyle` and `BoogiosOutlineToggleStyle` for binary settings.
- `BoogiosBottomSheet` for focused modal choices.
- `BoogiosWebView` and `BoogiosWebSheetView` for terms, privacy, and support.
- `SettingSectionCard` and `SettingRow` for grouped Settings content.

## Component Measurements

- Primary button: `boogiosMain` fill, `boogiosWhite` text, Pretendard SemiBold
  15, radius 14, vertical padding 15.
- Text field: `body1`, `boogiosWhite` fill, radius 14, horizontal padding 16,
  vertical padding 14, 1pt `boogiosGray3` border.
- Standard card: `boogiosWhite` fill, radius around 16, padding 16-20.
- Setting row: one-line title with an optional trailing value or chevron;
  preserve a 44pt or larger hit area.
- Primary action: make the action visually dominant and place it consistently
  near the bottom or immediately after the relevant content.
- Touch targets: keep practical tap areas at 44pt or larger.

## Onboarding Defaults

The template onboarding uses two introduction pages, a required 1-20 character
nickname field, notification guidance, and advertising privacy guidance. Keep
the existing brand tokens and the full-width primary button when adapting the
flow to a product. Product-specific copy belongs in `OnboardingL10n.swift`.

## After Creating A New App

Update app-local identity before designing detailed screens:

- `AppConfig.appName`
- `AppConfig.mainColorHex`
- App icon and launch imagery if needed
- Support, terms, and privacy URLs
- Any product-specific empty states, onboarding copy, and sample data

Keep app-specific design decisions inside the generated app. Do not change the
workspace template for a single app unless the change should apply to future
Boogios apps too.

## Settings Screen Defaults

The default Settings tab is a first-class template surface and should remain
available in generated apps.

- Keep the premium subscription card at the top when Premium is configured.
- Follow it with grouped sections for preferences, links, and app information.
- Keep language, theme, developer apps, support, terms, privacy, app version,
  onboarding replay, and review request entries unless the product explicitly
  narrows the scope.
- Open external pages with the existing web view or web sheet components.
- Show the UMP privacy choices entry point only when AdMob is configured and
  privacy choices are required.
- Do not put notification settings in the default template Settings screen;
  notification permission guidance belongs to onboarding or a product-specific
  feature when needed.

## Premium And Paywall Defaults

The template includes a settings-top premium card and a reusable
`PremiumPaywallView`.

- Explain the value of Premium before showing purchase choices.
- Present benefits in short rows with a clear visual hierarchy.
- Use StoreKit product display names and prices supplied by the App Store rather
  than hardcoding localized prices.
- Keep monthly, yearly, and lifetime products optional so placeholder product IDs
  do not block the rest of the app.
- Provide restore purchases and a clear active-entitlement state.
- Keep all paywall copy in `PremiumL10n.swift`.
- Treat failed, pending, unavailable, and restored purchase states as normal UI
  states with localized feedback.

## Localization Defaults

Every generated app keeps the 10 selectable language options represented by
`AppLanguage`:

- System default
- English (US), UK, Canada, and Australia
- Korean
- Japanese
- German
- French
- Portuguese (Brazil)
- Vietnamese

Add user-facing copy through a feature-level localization helper such as
`HomeL10n`, `MyPageL10n`, `OnboardingL10n`, or `PremiumL10n`; do not hardcode
strings directly in SwiftUI views. Keep the matching `InfoPlist.strings`
resources under `Global/Localizing/` and consider longer translations when
choosing fixed widths or one-line layouts.

## SDK And Configuration Defaults

Keep app-level keys and placeholders in `Configs/AppSecrets.xcconfig` and
`AppConfig`. Real app-specific values belong only in ignored local config files.

- `AdMobManager`: request UMP consent before starting AdMob or requesting ads.
- `TrackingAuthorizationManager`: request ATT only when AdMob is configured,
  and coordinate it with the onboarding privacy step.
- `MixpanelManager`: initialize only with a configured token; keep user
  properties and events behind the manager.
- `PremiumStore`: keep StoreKit product loading, purchases, restores, and
  entitlement refresh in one observable store.
- `NotificationAuthorizationManager`: request notification permission only when
  the onboarding flow reaches its notification step.
- `AppReviewRequester`: use the system review request from the Settings menu;
  do not show a custom rating dialog.
- Supabase values are placeholders only; add the actual SDK, authentication, and
  database behavior per product.

AdMob, ATT, Mixpanel, StoreKit, notifications, and external links must remain
safe when their configuration is missing. A placeholder configuration should
produce an empty or unavailable state, not a broken screen or an external
request.

## Growth Path

Keep the starter folders while screens are small. When one feature view grows
beyond roughly 500 lines or contains several independent sheets or sections,
move it to `Features/<Feature>/` and split it by screen responsibility.

- Keep state ownership in the parent feature view during a structural split.
- Introduce a view model when business state or async behavior needs an
  independently testable owner.
- Route UserDefaults, cloud sync, notifications, widgets, watch connectivity,
  review prompts, and SDK singletons through an app-local dependency container
  before a store becomes responsible for multiple external systems.
- Add or update unit tests for every dependency seam and retain the default live
  dependency so existing app entry points do not need special setup.

## Before Finishing Template Changes

- Confirm `MainView` still contains a `MyPageView()` tab tagged as
  `AppTab.myPage`.
- Confirm the app entry point injects `SettingsStore`, `OnboardingStore`, and
  `PremiumStore` into the environment as required.
- Confirm the app entry point applies the selected `AppTheme` with
  `.preferredColorScheme(settingsStore.selectedTheme.colorScheme)`.
- Confirm the 10 language options, localization helpers, and matching
  `InfoPlist.strings` files are present.
- Confirm placeholder AdMob, ATT, Mixpanel, StoreKit, and Supabase settings do
  not trigger invalid external requests.
- Regenerate the Xcode project with `xcodegen generate` after changing
  `project.yml`.
- Run the relevant unit, UI smoke, and simulator build checks.
- For release work, inspect `fastlane/Fastfile`, `fastlane/Appfile`, and
  `fastlane/.env` from the app root before upload or App Store review
  submission.

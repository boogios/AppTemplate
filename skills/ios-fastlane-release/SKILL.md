---
name: ios-fastlane-release
description: Use when releasing an iOS app to TestFlight or App Store Connect with fastlane, including new uploads, resubmissions, metadata or screenshot sync, Asset Library creative images for product page headers and search results, build and version bumps, and review submission follow-through.
---

# iOS Fastlane Release

Use this skill when the user asks to upload, resubmit, prepare, or finish an iOS release through fastlane.

## Trigger cases

- Upload a new iOS build to TestFlight or App Store Connect
- Re-upload after rejection with a new build number
- Sync App Store metadata or screenshots
- Prepare, upload, audit, or place localized Asset Library header/search creative images
- Submit a processed build to review
- Diagnose a fastlane release that failed partway through

## Workflow

1. Work from the real iOS release root that contains `fastlane/`, `Gemfile`, or the app project.
2. Set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
3. Inspect `fastlane/Fastfile`, `fastlane/Appfile`, `Gemfile`, and the project layout before running any lane.
4. Confirm release credentials and required metadata sources exist without printing secrets:
   - App Store Connect API key or Apple session auth
   - bundle identifier and team context
   - review contact email and phone
   - support, privacy, and marketing URLs when the lane submits to review
   - service terms URL and App Store copyright if the repo tracks them in env
5. If another local iOS repo on the same machine already has a working `fastlane/.env`, prefer copying the App Store Connect API key values into the new repo's local `fastlane/.env` instead of retyping them.
   - Copy only local secret files such as `fastlane/.env`
   - Map variable names if the source repo uses different key names
   - Never copy secret values into `SKILL.md`, tracked repo files, `.env.default`, or any committed template
   - Never print secret values in terminal output or the final response
6. Confirm app-specific public metadata for each deployment. The following are placeholders; replace them with your own verified values before release:
   - review contact email: `your-email@example.com`
   - review contact phone: `+00 0000000000`
   - marketing URL: `https://example.com`
   - support URL: `https://example.com/support`
   - App Store copyright: `2026 BOOGIOS_STUDIO` (App Store Connect requires the year and rights holder)
   - App Store primary category: `Apps.DeveloperTools` (App Store Connect label: `Developer Tools`)
   - privacy URL and service terms URL are app-specific and must be confirmed per app
   - Before running `prepare_app_review_metadata`, `beta`, or `release`, verify that the lane's marketing URL and copyright fallback resolve to the fixed values above, including the year in the copyright value
   - If app-local Fastlane metadata contains a different marketing URL or copyright, update those fields to the shared defaults before release unless the user explicitly overrides them
7. If lane names are unclear, run `bundle exec fastlane lanes` and follow the repo's existing release flow instead of inventing a new one.
8. If metadata changed, run the repo's metadata preparation or `deliver`-style step before the upload lane.
   - In App Store description feature lists, use the square bullet `■` to match the user's existing app-listing style; do not use round bullets such as `•`.
9. If screenshots changed, use the screenshot-only safety flow below before binary upload or review submission. A single release command may upload screenshots, audit them, and then upload/submit the binary sequentially. Never submit until the screenshot audit succeeds; disable screenshot uploads in the final deliver call.
   - For every future first release and update, inspect the new localized header/search creative assets too. Follow [Creative assets](references/creative-assets.md) to install the separate app-local lanes, prepare accurate artwork, validate/audit it, and integrate ready artwork within the user's release scope. Preserve suitable approved art; report optional gaps without silently blocking the binary release. Library upload, version placement, asset approval and publication are distinct results.
10. Bump build or marketing version only in the repo's source of truth.
11. If the repo mirrors version values in multiple files, update every required location consistently before building.
12. Regenerate the Xcode project only when the repo uses a generator such as XcodeGen or Tuist.
13. Run the required preflight checks before any App Store/TestFlight upload or review submission:
   - localization preflight
   - metadata/screenshot locale consistency
   - build/version consistency
   - live App Store Connect copyright check: read the target version's actual `copyright` field and require the exact shared value `2026 BOOGIOS_STUDIO`; do not treat a local `.env`, Fastlane fallback, build, or upload result as proof of the remote value
   - if the live value differs, update the editable App Store Connect version or stop and report that the version is locked; never cancel or delete an in-flight review submission merely to change copyright without explicit authorization
14. Run the narrowest release lane that matches the user's request, such as prepare, upload, distribute, or submit.
15. Wait for build processing and verify whether fastlane completed the intended stopping point:
   - upload only
   - TestFlight distribution
   - App Store review submission
16. If App Store Connect blocks the flow, fix the real blocking field or project setting and rerun only the necessary step.

## Screenshot upload safety

Treat screenshot upload as a separate, stateful operation. App Store Connect can be eventually consistent: a screenshot may upload successfully but remain absent from an immediate list response. Fastlane 2.228.x may interpret that delay as a missing screenshot and automatically upload the same checksum again.

1. Build the final localized screenshot folders before contacting App Store Connect.
2. Verify each locale and device set has at most 10 images and no duplicate local checksums.
3. Inspect the target version state. Stop before changing screenshots on a locked or under-review version. Never cancel review automatically; cancellation requires explicit authorization.
4. Read [current screenshot sizes and app-local integration](references/app-store-screenshots.md). Use locked Fastlane 2.241.2 for the validated Duo path. Earlier versions may reject Duo dimensions. Both Duo postures map to APP_IPHONE_DUO, with **10 images total per locale**, not 10 each.
5. Validate actual exports, expected locales and display sets, then stage the ordered manifest. Require real posture-specific captures and ready translations. Install app-local copies of the scripts from this skill when an existing app needs integration.
6. Run the app's `upload_store_screenshots` lane, or the bundled `scripts/app_store_screenshot_sync.rb --manifest <manifest> --upload`. Without `--upload` the script audits only. A changed selected set is replaced; matching sets are skipped. The old `--replace` switch is an alias for upload but still requires a validated manifest.
7. Finish with exact ordered remote checksums, expected count per locale/display, complete processing and zero duplicate groups. Incomplete or unknown results stop the release. Preserve `.store-assets` journals and read back before retrying; do not clear state or blindly resend a timed-out POST.
8. Continue binary upload/review with screenshot upload disabled. `RELEASE_SKIP_SCREENSHOTS=true` skips screenshot writes; when submitting for review, still audit the prepared local manifest against the remote version. Keep optional header/search creative-asset lanes and their approval/publication rules separate.

## Required localization preflight

Run this before uploading or submitting any app that supports more than one locale.

- Identify supported locales from every source of truth:
  - `*.lproj` folders
  - app-local localization helpers such as `L10n`, `Strings`, or `Localizable`
  - `fastlane/metadata/*`
  - screenshot config/output folders
- Check that app display names exist for every supported locale, usually in `InfoPlist.strings`.
- Search for hardcoded user-visible Korean/Japanese/English strings outside the localization layer.
  - Korean text outside `ko:` values or `ko.lproj` is a release blocker.
  - Japanese text outside `ja:` values or `ja.lproj` is a release blocker.
  - English literals in SwiftUI views should be intentional symbols such as `O`, `X`, `OK`, or debug-only strings; otherwise localize them.
- If the app uses a custom localization helper, verify every user-visible call includes all supported language arguments and does not silently fall back to Korean for global users.
- For global apps, the default fallback should normally be English unless the app is Korea-only.
- Verify legal/privacy/terms screens, onboarding, home, game flow, result, ranking, settings, alerts, toasts, ad labels, and review prompts.
- If screenshots are being uploaded, ensure each App Store locale uses either localized screenshots or intentionally shared language screenshots.
- When simulator/UI verification is allowed, launch one non-Korean locale, preferably Japanese, and confirm no mixed-language screen appears. If simulator launch is not allowed, report that this visual check was skipped and rely on static checks only.

Useful static checks:

```sh
rg -n "[가-힣]" . --glob "*.swift"
rg -n "Text\\(\"|Button\\(\"|Label\\(\"|navigationTitle\\(\"" . --glob "*.swift"
find . -type d -name "*.lproj" -maxdepth 5
```

## Repo-specific decision points

- Do not assume every repo uses `fastlane ios release`; many repos split the flow into `prepare`, `beta`, `release`, or `submit`.
- Do not assume version numbers live in one file; check `project.yml`, `.xcconfig`, `Info.plist`, build scripts, and lane parameters first.
- Do not regenerate projects unless the repo actually depends on generated Xcode files.
- If the app has no live version yet, skip `What's New` text for the first App Store release.
- If localization creation fails in fastlane, prefer updating an existing locale or finishing the missing field in App Store Connect UI rather than forcing a broken automation path.
- Keep export compliance and encryption answers aligned with the actual app; do not blindly reuse another repo's settings.

## Useful checks

- `bundle exec fastlane lanes`
- `bundle exec fastlane env`
- `bundle exec fastlane <platform> <lane> ...`
- Confirm the generated `.ipa` path and build number before upload.
- Confirm whether fastlane reported successful metadata upload, screenshot upload, and review submission separately.
- Confirm localization preflight passed, or clearly report the exact skipped manual visual checks.

## Verification

- Confirm the exported `.ipa` path or organizer artifact location.
- Confirm the uploaded build number is visible in App Store Connect.
- Confirm metadata and screenshots were uploaded when requested.
- Re-read the target version in App Store Connect after metadata preparation and verify `copyright == "2026 BOOGIOS_STUDIO"` exactly, including capitalization, spacing, and year.
- Confirm localization preflight was completed before submission.
- Confirm the release ended in the intended state:
  - uploaded only
  - available in TestFlight
  - waiting for review
  - blocked pending manual follow-up

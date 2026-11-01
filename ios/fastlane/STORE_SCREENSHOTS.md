# App Store screenshot contract

Verified 2026-10-28 against [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [Fastlane 2.241.2](https://github.com/fastlane/fastlane/blob/2.241.2/deliver/lib/deliver/app_screenshot.rb).

| Export | Portrait pixels | App Store display type |
|---|---|---|
| iPhone Dynamic Island medium | 1206×2622 (also 1179×2556) | APP_IPHONE_61 |
| Legacy large iPhone | 1290×2796 (also 1260×2736, 1320×2868) | APP_IPHONE_67 |
| Duo outer | 1398×2034 | APP_IPHONE_DUO |
| Duo inner | 2007×2853 | APP_IPHONE_DUO |
| iPad 13-inch | 2048×2732 or 2064×2752 | APP_IPAD_PRO_3GEN_129 |

Landscape swaps width/height. Use flattened RGB PNG or JPEG. Apple requires a
medium Dynamic Island iPhone screenshot and iPad 13-inch screenshots when the app
supports iPad. Duo screenshots become required in April 2027 for iOS 27.1 SDK+
according to the detailed screenshot specification; Apple's announcement uses
broader wording. Recheck before a release. Do not infer an exact day.

**Duo outer and inner share a single maximum of 10 images per locale.** Upload
card 1 outer, card 1 inner, card 2 outer, card 2 inner. If that exceeds 10, select
cardSlugs in each device config; never silently truncate. These are local export
device keys, not two separate App Store display sets. Keep real captures for each
posture and locale. A phone capture stretched to a Duo canvas is not Duo evidence.
For the template capture helper, set SIMULATOR_UDID and SIMULATOR_DISPLAY to the
actual display UUID returned by `xcrun simctl io <udid> enumerate`. The default
display can remain the outer display after unfolding. The helper checks posture
aspect ratio; match the board orientation to the actual portrait/landscape capture.

Template exports use `iphone63`, `duoOuter`, `duoInner`; `iphone69` and `ipad13`
remain available. Enable iPad only for an iPad-supported app. Store captures in
`AppStoreScreenshots/captures/<device>/<locale>/<card>.png`, and exports in
`outputs/appstore-exports/<locale>/*.png`. Shared-language captures require an
explicit `sharedCaptureLocales` mapping. Draft/placeholder output is preview-only.

The validator's manifest records ordered image paths, dimensions, format, alpha
state, SHA-256/SHA-1/MD5 and display groups. The renderer writes export-status.json;
template submission refuses draft/placeholder exports. This does not prove that
captures show the current app or that the app resizes correctly. Inspect real
folded/unfolded UI before preparing a product's release.

## Validation and Fastlane integration

Install Pillow with `python3 -m pip install -r fastlane/lib/requirements.txt` in
an app-local Python environment if needed. Use a supported Ruby (3.2+ recommended),
`bundle install`, and the app's locked Fastlane. Don't install or patch system gems.

```sh
bundle exec fastlane ios validate_store_screenshots
bundle exec fastlane ios upload_store_screenshots version:1.2.3
bundle exec fastlane ios audit_store_screenshots version:1.2.3
bundle exec fastlane ios release version:1.2.3
```

In generated apps the release lane stages images, uploads sequentially, confirms
ordered remote checksums and processing, then calls deliver with screenshot
upload disabled. `RELEASE_SKIP_SCREENSHOTS=true` skips writes but still audits
screenshots before review submission. Binary-only uploads without review may
skip screenshot preparation. Preserve the existing submit/automatic-release flags.

For an existing app, install `store_screenshots.py`, `store_screenshot_sync.rb`,
`requirements.txt` in `fastlane/lib/` and the `store_assets.Fastfile` beside its
Fastfile. Adapt only the app root, identifier, version, locale and export-config
accessors. Keep scripts app-local; do not depend on a personal skill path.

The sync CLI accepts `--manifest <path>` and defaults to a remote audit; `--upload`
enables writes (`--replace` is an alias). API credentials accept ASC_KEY_ID /
ASC_ISSUER_ID / ASC_KEY_FILEPATH or APP_STORE_CONNECT_API_KEY_* names. Supply the
exact target APP_IDENTIFIER and APP_VERSION. Secrets never enter the manifest.

Do not cancel an active review automatically. Under-review/locked versions stop
before screenshot mutation. Resume with the same input manifest and journal in
`fastlane/.store-assets/`. Matching sets are skipped; only changed selected sets
are replaced. Unknown POST results stop for bounded read-back; never clear the
journal to force a retry. Read-back must confirm count, processing, no duplicates
and ordered checksums. If a prior request remains invisible, report the blocker.
An upload/audit is not approval, submission or publication.

The default read-back budget remains 10 polls at 3-second intervals. If Apple
reports `UPLOAD_COMPLETE` while processing is still pending, preserve the journal
and read the current state before resuming. `STORE_SCREENSHOT_POLL_ATTEMPTS=100`
allows up to 5 minutes of polling intervals (network request time is separate); `STORE_SCREENSHOT_POLL_INTERVAL` defaults
to 3 seconds. Invalid values or polling intervals totaling above 300 seconds fail before contacting
the store. This extends reads only; it never repeats an uncertain upload.

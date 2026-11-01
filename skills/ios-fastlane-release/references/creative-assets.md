# Product page header and App Store search creative assets

Use this workflow for **every future iOS first release and update**: inspect whether
the app has localized header/search artwork, retain approved suitable placements,
and prepare missing artwork when marketing/release preparation is in scope.
These assets are optional in App Store Connect. Do not block an otherwise authorized
binary release just because optional artwork is unavailable or awaiting its own review;
report the gap and the next step. Do not reuse another app's artwork or unsupported claims.

## Install in an existing app

1. Read app-local instructions and Git status. Preserve the existing release lanes.
2. Copy `scripts/app_store_creative_assets.rb` and `scripts/creative_assets.Fastfile`
   from this skill to the target app's `fastlane/` directory. Add
   `import "./creative_assets.Fastfile"` to the app's `Fastfile` after its constants.
   Update existing copies narrowly if installed already. There is no new gem dependency.
3. Ensure `APP_IDENTIFIER` / `BUNDLE_IDENTIFIER`, or the app's existing
   `DEFAULT_APP_IDENTIFIER` / `DEFAULT_BUNDLE_ID`, identifies the intended app.
4. Ignore `fastlane/.creative-assets-state/` in the app's Git root. Keep this local
   resume ledger across retries. Do not clear it to work around a failed operation.
5. Read API credentials from the app-local ignored environment. Supported names:
   `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_FILEPATH`, or
   `APP_STORE_CONNECT_API_KEY_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`,
   `APP_STORE_CONNECT_API_KEY_PATH`. The `.p8` filepath is required; secrets must
   never enter the manifest, state, source, or logs.

Boogios `AppTemplate/fastlane` includes these files and imports the lanes, so the
existing new-app generator copies them automatically. Its `manifest.example.json`
is a schema example only; use real approved assets and the actual numeric app ID.

## Prepare the app-local manifest

Default path: `fastlane/creative_assets/manifest.json`. Override with lane parameter
`manifest:<path>` or `CREATIVE_ASSETS_MANIFEST`. Relative manifest/state parameters
resolve from the app release root; image paths resolve from the manifest directory.

```json
{
  "app_id": "1234567890",
  "bundle_id": "com.example.app",
  "placements": ["header", "search"],
  "assets": [
    {
      "locale": "en-US",
      "file": "en-US/universal.png",
      "sha256": "FULL_SHA256_OF_THE_FINAL_APPROVED_PNG"
    }
  ]
}
```

The first implementation supports one **5244 × 2950, 8-bit RGB PNG without alpha**
per locale, usable for both header and search. It validates PNG structure/CRCs,
dimensions, transparency and the recorded SHA-256 before any remote mutation.
App Store specifications, compatible placement groups and limits are read live,
including the assigned `specId`; never hard-code Apple's spec UUID.

Match locales to the actual version localizations and supported listing languages.
For English regions that intentionally share art, identical SHA-256 files upload
once and the resulting asset is reused. Native-language review and Apple preview
remain separate from file validation. Do not treat generated composited UI as real
in-app screenshots; use accurate app visuals and review text/cropping before upload.

## Run the narrow operation

```sh
bundle exec fastlane ios validate_creative_assets
bundle exec fastlane ios audit_creative_assets version:1.2.3
bundle exec fastlane ios upload_creative_assets
bundle exec fastlane ios place_creative_assets version:1.2.3
```

- `validate`: local files only; no credentials or network required.
- `audit`: GET only; verifies app/bundle, library, current spec availability and
  tracked/deterministically named images. With `version`, reports its state and
  missing manifest locales plus every header/search slot's linked image, placement
  state and whether it is empty, matches the manifest, or contains other artwork.
- `upload`: reserves each unique image, transfers the exact byte ranges without
  JWT, commits **only `uploaded: true`**, then polls for processing and checks
  the returned dimensions/spec. It never creates a version, places art, deletes,
  submits to review, or publishes.
- `place`: requires an explicit, existing, editable iOS version and every manifest
  locale. Preflights all target slots before writes, then rechecks each slot and
  the parent state. Reuses matching placements; different existing artwork stops
  the operation for scoped inspection/replacement in App Store Connect. No implicit
  deletion, review cancellation, version creation, submission, or publication.

The narrow editable allowlist is `PREPARE_FOR_SUBMISSION`, `DEVELOPER_REJECTED`,
`REJECTED`, `METADATA_REJECTED`. All other parent states stop placement writes.

## Release integration and authorization

The user's standing preference is to include this new header/search artwork in
future app releases and updates. During release preparation, inspect missing
placements/artwork, install the lanes when needed, prepare/localize accurate
app-specific artwork, run validation and a read-only audit, and include the
creative-artwork result in the release report.

An explicit request to upload/sync listing assets authorizes the corresponding
upload/placement work within the target app. A request to release/update an app
with this standing preference permits integrating ready artwork in that release
scope. Do not turn an inspection/draft request into an upload, review submission,
publication, or modification of other apps. The lanes are separate deliberately;
the existing `beta`/`release` lanes do not silently invoke mutating creative lanes.

- **First release / editable new version:** finish ordinary localized metadata,
  audit and upload ready artwork, then place it on that explicit version before
  the already-authorized parent review submission. Verify live placement IDs/types,
  linked image IDs and processing/review states separately from binary status.
- **Existing live version (`READY_FOR_SALE`, `READY_FOR_DISTRIBUTION`, approved):**
  upload can stage images in the library, but `place` refuses the locked parent.
  Use the authenticated App Store Connect Asset Library to submit creative assets
  for approval, then browse/select approved assets for header/search and publish
  within the user's authorized scope. Do not create an unnecessary app version,
  cancel review, or claim public availability from an upload result.
- **Existing different placements:** inspect the precise locale/type and artwork.
  Apple requires deleting and recreating the placement to change its image. This
  script intentionally does not replace automatically; complete an authorized
  scoped replacement through App Store Connect and verify the resulting selection.

## Recovery and verification

- Mutating runs take an app-local file lock and atomically save a non-secret ledger.
  Deterministic references include app ID and full local SHA-256. Lookup uses both
  library list and recorded IDs to survive delayed list visibility.
- Reserve/placement intent is persisted **before POST**. Network or processing
  failures never trigger another reservation automatically. Rerun `audit`, then
  resume `upload` or `place`; a pending POST with no visible resource stops for
  reconciliation. Do not clear state or delete resources merely to retry.
- For an `AWAITING_UPLOAD` reservation, resume transfer using its current upload
  operations; for `UPLOAD_COMPLETE`, poll processing. `timeout:<seconds>` defaults
  to 300. `FAILED`, `REJECTED`, `ARCHIVED`, conflicting images, missing locales,
  or changed files stop with a concrete reason.
- API does not expose a remote source checksum for these images. A matching local
  ledger/reference/size/spec is **not independent remote checksum equality**.
  Review the Apple-rendered preview to verify the actual artwork.
- Report local validation, library upload/processing, placement, asset approval,
  parent review, publication and public visibility independently. Mock tests and
  GET-only audits are not proof of successful real uploads/placements.

## Primary sources (verified 2026-10-13)

- [Uploading and managing image assets](https://developer.apple.com/documentation/appstoreconnectapi/uploading-and-managing-image-assets)
- [Placing assets on your App Store surfaces](https://developer.apple.com/documentation/appstoreconnectapi/placing-assets-on-your-app-store-surfaces)
- [Understanding the App Asset Library](https://developer.apple.com/documentation/appstoreconnectapi/understanding-the-app-asset-library)
- [API 4.5.1 release notes](https://developer.apple.com/documentation/appstoreconnectapi/app-store-connect-api-4-5-1-release-notes)

Fastlane 2.228.0 and 2.241.0 did not include native new creative-library support
when checked; this app-local implementation calls the official ASC API using
Fastlane's existing Spaceship token support. Recheck native support before future
migration rather than treating `app_clip_header_images_path` as product-page art.

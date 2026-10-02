---
name: android-fastlane-release
description: Use when releasing an Android app to Google Play with fastlane supply, including new AAB or APK uploads, resubmissions, localized Play metadata or screenshot sync, track promotion, version-code changes, review submission follow-through, and diagnosing a release that stopped partway through.
---

# Android Fastlane Release

Use this skill when the user asks to upload, resubmit, prepare, or finish an
Android release through fastlane and Google Play Console.

## Shared Play service-account credential

Use one local Google Play service-account JSON for every Boogios Android
project. The canonical default path is:

```text
${HOME}/.config/boogios/google-play-service-account.json
```

Resolve the credential in this order:

1. `BOOGIOS_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` when an explicit shared or CI
   path is supplied
2. `SUPPLY_JSON_KEY_PATH`, the standard fastlane override
3. `SUPPLY_JSON_KEY`, `GOOGLE_PLAY_JSON_KEY`, or
   `GOOGLE_APPLICATION_CREDENTIALS` for legacy or provider-compatible setups
4. the canonical path above

Do not use `fastlane/play-console-service-account.json` or another
project-local path as the default, and do not copy the JSON into an app
repository. Before an upload, confirm that the resolved file exists and is
readable without printing its contents. Pass that resolved path to the
project's `json_key`/`json_key_file` option or export it as
`SUPPLY_JSON_KEY_PATH` for the lane. If no override or canonical file exists,
ask the user to place the existing secret at the canonical path or configure
one of the overrides; do not ask for a different path for each app.

## Shared Android upload keystore

Use the existing common upload keystore for Boogios Android projects by
default:

```text
${HOME}/.android/boogios-common-upload.jks
```

Use alias `boogios-common-upload`. Resolve the keystore password from the
macOS Keychain entry with service `Boogios Android Common Upload` and account
`boogios-common-upload`; never put the password in `SKILL.md`, a tracked
`.env`, a log, or chat. Only use a project-specific keystore path or alias
when the project's signing configuration and Play upload history prove that
it is required. The common keystore path must remain the default across
projects.

## Trigger cases

- Upload a new Android AAB or APK to Google Play
- Re-upload after rejection, failed processing, or a version-code change
- Sync Play Store titles, descriptions, release notes, graphics, or screenshots
- Publish to internal, closed, open, or production tracks
- Promote an existing track release or configure staged rollout
- Submit pending Play Console changes for review or verify a release result
- Diagnose a fastlane, Gradle, signing, metadata, or Play API failure

## Workflow

1. Work from the real Android release root containing `fastlane/`, `Gemfile`,
   `gradlew`, and the Android project. Do not assume the repository root is the
   Android release root.
2. Inspect `fastlane/Fastfile`, `fastlane/Appfile`, `Gemfile`, `Gemfile.lock`,
   `build.gradle`/`build.gradle.kts`, `gradle.properties`, metadata source
   folders, and release scripts before running any lane.
3. Run `bundle exec fastlane lanes` and follow the repository's existing lane
   names. Do not invent a release lane when a working project lane exists.
4. Confirm the package identity from the effective `applicationId`, not only
   the namespace or a README. Verify the target Play app and account before any
   upload.
5. Confirm release credentials without printing secrets:
   - the resolved shared Play service-account JSON using the credential rule
     above
   - Play Console app permission for the service account
   - the shared Android upload keystore, alias, and Keychain-backed password
     using the rule above
   - Android SDK, JDK, and Gradle wrapper availability
6. If the shared Play credential or common upload keystore is missing, ask the
   user to place/configure the local secret using the canonical rules above.
   Never ask them to paste private keys, JSON contents, keystore passwords, or
   tokens into chat.
7. Identify the version from the actual release source of truth and the remote
   Play track. Require an explicit `version_name` and monotonically increasing
   `version_code` for build and upload lanes. Never silently reuse a default
   `1.0.0`/`1` release value for a new upload.
8. Identify the intended track and stopping point before mutating Google Play:
   - metadata-only upload
   - internal or closed test upload
   - production draft upload
   - review submission
   - completed or staged public release
9. If metadata changed, run the repository's metadata sync and validation lane
   before building or uploading. Treat generated `fastlane/metadata/android`
   files as a derived copy when the repository has a tracked source such as
   `play/metadata`.
10. If screenshots changed, use the screenshot safety flow below. Do not let a
    combined release lane blindly replace remote screenshots and submit for
    review in the same pass.
11. Run the required preflight checks before any Play upload:
    - package and version consistency
    - signing and AAB/APK artifact checks
    - localized metadata field limits
    - locale and device-category consistency
    - privacy, data-safety, app-content, and review prerequisites where the
      repository tracks them
12. Run the narrowest lane matching the user's request. Prefer a draft upload
    for production when the final Play Console review submission is a separate
    explicit action.
13. Verify the actual remote stopping point in Play Console. Distinguish:
    - local build completed
    - AAB uploaded and processed
    - draft release created
    - changes submitted for review
    - review approved
    - release publicly available
14. If Play Console blocks the flow, fix the real blocking field or project
    setting and rerun only the necessary step. Do not upload another identical
    bundle merely because the UI is still processing.

## Metadata and screenshot source of truth

Use the project's tracked metadata source first. Common layouts include:

```text
play/metadata/<locale>/title.txt
play/metadata/<locale>/short_description.txt
play/metadata/<locale>/full_description.txt
play/metadata/<locale>/release_notes.txt
play/screenshots/<locale>/phone/*.png
play/screenshots/<locale>/seven-inch/*.png
play/screenshots/<locale>/ten-inch/*.png
```

Fastlane supply commonly consumes the derived layout:

```text
fastlane/metadata/android/<locale>/title.txt
fastlane/metadata/android/<locale>/short_description.txt
fastlane/metadata/android/<locale>/full_description.txt
fastlane/metadata/android/<locale>/changelogs/<version_code>.txt
fastlane/metadata/android/<locale>/images/icon.png
fastlane/metadata/android/<locale>/images/featureGraphic.png
fastlane/metadata/android/<locale>/images/phoneScreenshots/*.png
```

Keep source and generated paths separate. Never edit an ignored generated copy
when a sync script will overwrite it. Preserve locale codes exactly as used by
the repository and Play Console.

## Screenshot upload safety

Treat screenshot upload as a stateful remote operation. Google Play can accept
an upload while the image list is still eventually consistent, and a retry can
create duplicate work or replace a complete set unnecessarily.

1. Build the final local screenshot folders before contacting Play.
2. Verify every intended locale and device category has the expected count,
   valid dimensions, supported format, and unique local checksums.
3. Audit the remote screenshot set before re-uploading. Compare remote counts
   and checksums where the project has a verification script or API helper.
4. Upload only missing or incomplete locale/device sets when possible. Use
   `sync_image_upload` or an equivalent checksum-aware option when supported by
   the installed fastlane version.
5. If Play reports processing, missing, or duplicate screenshots, wait and
   re-audit before retrying. Do not blindly rerun a combined `supply` lane.
6. If a review is already active, verify whether changing screenshots will
   cancel or restart review before making the change. Explain the consequence
   to the user when Play presents that warning.
7. After a separately verified screenshot repair, upload the binary or submit
   review with screenshot upload disabled when the lane supports it.

## Required Android release preflight

Run the repository's equivalent of these checks before upload:

```sh
bundle exec fastlane lanes
bundle exec fastlane android bootstrap_check
bundle exec fastlane android prepare_metadata version_code:<code>
bundle exec fastlane android build_release version_name:<name> version_code:<code>
```

Also verify, using the available local tools:

- the built AAB/APK has the intended package name, version name, and version
  code
- the artifact is signed with the expected upload key
- `targetSdk` and min SDK match the release decision
- all required Play locales have title, short description, full description,
  and release notes within the repository's validated limits
- screenshot counts and device categories match the intended listing
- privacy policy, data-safety, app-content, ads, target-audience, and app-access
  requirements are complete in Play Console when applicable

For an AAB, do not use an APK-only badging command as proof of bundle contents.
Prefer `bundletool` or the project's artifact inspection script, and use
`jarsigner -verify` or an equivalent signing check for the signature.

## Track and release-state rules

- Use `internal`, `alpha`/closed, `beta`/open, or `production` only after
  confirming the user's intended destination.
- Treat `release_status: draft` as an upload stopping point, not public release.
- Treat `release_status: completed` as a higher-impact action; use it only when
  the user explicitly authorizes completion on that track.
- A production AAB upload does not by itself prove that the app is publicly
  searchable or installable.
- A Play Console submission record does not by itself prove that the latest
  version is live. Verify the production track and public listing separately.
- Organization-account status may change the available testing path, but do
  not infer that testers are unnecessary until Play Console accepts the
  production submission without a testing blocker.
- If managed publishing is enabled, approval may not publish automatically;
  inspect the publishing overview and follow the configured publish action.

## Play Console review follow-through

Fastlane supply can upload the AAB and listing assets, but a draft upload may
still require an explicit Play Console action. After a draft upload:

1. Open the correct app and developer account in Play Console.
2. Check the production or intended track for the uploaded version and bundle
   version code.
3. Open **게시 개요** and inspect pending changes.
4. Submit **검토를 위해 변경사항 제출** only when the user authorized review
   submission and the pending change set is correct.
5. If Play warns that an existing review will be canceled and restarted,
   explain the new wait-time consequence and proceed only when the request
   covers that resubmission.
6. Verify **제출 활동** and the track page independently after submission.
7. Report whether the final state is draft, under review, approved, published,
   or blocked. Do not report “released” from a local Fastlane log alone.

## Credentials and information to request

Request only information that cannot be discovered safely from the project or
local environment:

- package name if the effective `applicationId` is ambiguous
- intended track and release status
- explicit version name and version code
- only whether the user can place the existing Play service-account JSON at
  `${HOME}/.config/boogios/google-play-service-account.json` or configure a
  credential override; do not request an app-specific path
- only whether the common upload keystore exists at
  `${HOME}/.android/boogios-common-upload.jks` and its password is available
  through the documented Keychain entry; do not request an app-specific path
  or secret contents in chat
- missing Play Console permissions or account selection
- missing locale, screenshot, privacy-policy, or review requirements

Do not store service-account JSON, keystores, passwords, or tokens in
`SKILL.md`, tracked files, templates, logs, or final responses.

## Useful checks

```sh
bundle exec fastlane lanes
bundle exec fastlane env
bundle exec fastlane android bootstrap_check
bundle exec fastlane android prepare_metadata version_code:<code>
bundle exec fastlane android build_release version_name:<name> version_code:<code>
bundle exec fastlane android upload_listing version_name:<name> version_code:<code>
bundle exec fastlane android internal_test version_name:<name> version_code:<code>
bundle exec fastlane android closed_test version_name:<name> version_code:<code>
bundle exec fastlane android production_draft version_name:<name> version_code:<code>
```

Use `bundle exec fastlane action upload_to_play_store` to confirm that options
such as `sync_image_upload`, metadata upload, screenshot upload, release status,
and track promotion are supported by the installed fastlane version.

## DayBlocks Android reference

When working in a DayBlocks checkout, use these project-specific defaults only
after verifying that the files still match the live app:

- Android release root: `<DayBlocks checkout>/android`
- package: `com.boogios.dayblocks.paid`
- tracked Play metadata: `android/play/metadata/`
- tracked Play screenshots: `android/play/screenshots/`
- generated supply metadata: `android/fastlane/metadata/android/`
- current lanes: `bootstrap_check`, `sync_metadata`, `prepare_metadata`,
  `validate`, `build_release`, `upload_listing`, `internal_test`,
  `closed_test`, `production_draft`
- `production_draft` builds and uploads a draft; final review submission is a
  separate Play Console action under **게시 개요**

Do not assume these paths, package values, lane names, or version values apply
to another Android app.

## Verification

- Confirm the built AAB/APK path and package/version values.
- Confirm the artifact is signed and Play processing completed when an upload
  was requested.
- Confirm metadata and screenshots were uploaded when requested.
- Confirm the intended track and release status in Play Console.
- Confirm review submission or public availability independently when requested.
- Clearly report any skipped emulator, device, screenshot-visual, processing,
  or public-listing checks.

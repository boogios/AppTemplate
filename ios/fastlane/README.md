fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios bootstrap_check

```sh
[bundle exec] fastlane ios bootstrap_check
```

Verify local Fastlane, XcodeGen, signing, and shared ASC key inputs

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build a Release ipa for TestFlight/App Store

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload a Release build to TestFlight

### ios prepare_app_review_metadata

```sh
[bundle exec] fastlane ios prepare_app_review_metadata
```

Prepare App Store Connect metadata without submitting for review

Uses `APP_STORE_NAME`, `APP_STORE_PRIMARY_CATEGORY`, and `APP_STORE_LOCALES` from
`fastlane/.env`. Keep `APP_STORE_LOCALE=en-US` so English is the default App
Store metadata language. The lane automatically appends `SERVICE_TERMS_URL` to
the App Store description so auto-renewable subscription apps include a
functional Terms of Use (EULA) link before review submission.

### ios sync_app_store_screenshots

```sh
[bundle exec] fastlane ios sync_app_store_screenshots
```

Sync exported App Store screenshots into fastlane deliver folders

### ios generate_app_store_screenshots

```sh
[bundle exec] fastlane ios generate_app_store_screenshots
```

Generate localized App Store screenshots from AppStoreScreenshots config

### ios release

```sh
[bundle exec] fastlane ios release
```

Build, sync metadata, and submit a version for App Store review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

# App Store header and search artwork

New apps include four independent Fastlane lanes:

```sh
bundle exec fastlane ios validate_creative_assets
bundle exec fastlane ios audit_creative_assets version:1.0.0
bundle exec fastlane ios upload_creative_assets
bundle exec fastlane ios place_creative_assets version:1.0.0
```

Copy `manifest.example.json` to `manifest.json`, set the real Apple app ID and
bundle ID, and add one final 5244 × 2950 8-bit RGB PNG without alpha per listing
locale. Image paths are relative to the manifest. Record the final SHA-256 with
`shasum -a 256 <image>` after artwork review. Identical artwork across locales
uploads once. Nothing runs automatically from `beta` or `release`.

Validation is local. Audit reads App Store Connect without changes. Upload adds
images to the asset library and waits for processing. Place connects them to an
explicit editable version and stops if the slot already contains different art.
These lanes do not submit, publish, replace existing art, or create app versions.
For a live version, finish creative approval/selection/publication in App Store
Connect within the authorized release scope.

Use existing app-local API credentials. Keep `.creative-assets-state/` across
retries; it prevents duplicate reservations when upload or network processing
stops partway through. The ledger contains no JWT or signed upload URLs.

The reusable workflow lives in
[the bundled skill reference](../../../skills/ios-fastlane-release/references/creative-assets.md).

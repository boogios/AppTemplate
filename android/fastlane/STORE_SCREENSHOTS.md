# Google Play screenshots

Verified 2026-10-28: https://support.google.com/googleplay/android-developer/answer/9866151

Use `play/screenshots/<locale>/<phone|seven-inch|ten-inch>/*.png` as tracked source.
Configure expected locales/categories in `play/screenshot-config.json`; missing
folders fail. Phone output defaults to 1080×1920, two images minimum in total,
eight maximum per category. Four 1080px app images are needed for recommendation
surfaces. Tablet exports use four real app captures, 1080..7680px, 16:9/9:16,
without external promotional copy. Phone/general limits are 320..3840px, <=2:1.
Use RGB PNG/JPEG, no alpha. Do not invent a Duo category for Play. Standard
routing covers phone/tablets, TV and Wear. Other form factors need a dedicated
workflow and are rejected rather than silently treated as phone.

Install `fastlane/lib/requirements.txt` in your Python environment and run
`bundle install` with a supported Ruby (3.2+ recommended). Fastlane is locked to
2.241.2. Commands: `bundle exec fastlane android validate_store_screenshots`,
`upload_store_screenshots`, `audit_store_screenshots`, then the existing `upload`.

`upload` handles assets first if source images exist or ANDROID_UPLOAD_SCREENSHOTS=true.
ANDROID_SKIP_SCREENSHOTS=true audits without writing. Explicitly requested missing
assets fail. Without assets/request the existing binary-only flow remains.
The derived upload folders are `fastlane/metadata/android/<locale>/images/`.
Only validated images are staged; metadata and unrelated device sets are retained.

Read the canonical shared service account through the documented environment
overrides or ~/.config/boogios/google-play-service-account.json. Never copy the
credential into an app. Supply uses a separate Play edit for screenshots, verifies
ordered SHA-256 and counts, commits changes_not_sent_for_review, and audits a fresh
edit. Preserve an uncertain-commit journal in fastlane/.store-assets and re-audit;
do not blindly repeat a commit. Matching sets are not replaced. The later AAB
call skips screenshot/image upload and retains the existing internal/draft
default. Listing upload, review submission and publication are different states.

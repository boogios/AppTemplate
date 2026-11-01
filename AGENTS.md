# Native App Templates

- Work only in the requested platform (`ios/` or `android/`), shared tool or skill scope. Preserve unrelated working changes.
- Read platform AGENTS.md, DESIGN.md and README.md before editing. iOS project.yml is the source of truth; regenerate with XcodeGen.
- Keep existing onboarding, nickname, notifications, ads, analytics, purchases, Settings, languages and theme behavior.
- New apps are independent copies. Feed shared fixes back with regression checks and module version changes; do not bulk overwrite existing apps.
- Secrets belong in ignored app-local files. Public examples must contain placeholders, without personal contact data, machine paths or credentials.
- Shared generator/check tools are in scripts/. Store asset tools are canonical in scripts/store_assets/; sync_tools.py maintains platform and bundled skill copies without reaching outside this repository.
- Follow docs/native-template-foundation.md and platform fastlane/STORE_SCREENSHOTS.md. Do not upload or submit during local validation. Review cancellation needs explicit authorization.
- Run local checks, generator and asset regression tests, then platform builds/tests appropriate to changed code. Report exact checks and unverified store/device behavior separately.

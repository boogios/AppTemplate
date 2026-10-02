---
name: screenshot-android
description: Create, compose with reusable HTML/CSS boards, resize, localize, and validate Android Google Play screenshots and preview graphics against current Play Console size, format, aspect-ratio, count, and device-category requirements. Use for emulator captures, HTML/CSS screenshot composition, app icon or feature graphic preparation, Fastlane supply assets, or diagnosing Play screenshot upload errors.
---

# Screenshot Android

Use this skill to prepare truthful Android app UI captures and Google Play
preview assets. Match the iOS screenshot workflow: capture the real app first,
compose each store card with reusable HTML/CSS, export one flattened PNG per
card, and validate every output before copying it into a Fastlane or Play
Console source folder. Do not use HTML to fake app UI; HTML/CSS is only for the
copy, background, spacing, and presentation around a real capture.

Start from
`assets/google-play-screenshot-template.html` for a new screenshot set. Keep
the `cards` data, device configuration, capture directory, and export directory
separate so the same copy system can be reused across locales and device
categories.

Read [Google Play asset requirements](references/google-play-assets.md) before
finalizing sizes. Google can change requirements, so recheck the official page
when a release is imminent.

## Best fit

- Google Play screenshot draft boards
- Localized phone and tablet screenshot sets
- Feature graphics and preview assets
- Reusable HTML/CSS screenshot systems shared across Android apps
- Real emulator captures that still need copy, background, and export framing

## Core workflow

1. Lock the Google Play storefront target first.
   - Confirm the app, package, locales, and device categories.
   - Prefer real emulator or device captures when the app has stable screenshot seed data.
2. Lock one export size per device category before styling.
   - Keep final board output pixel-locked.
   - Keep capture resolution and board resolution explicit.
3. Keep one board per screenshot.
   - Repeated DOM structure
   - Easy reorder, remove, and duplicate
4. Separate content from layout.
   - Shared `cards`
   - Device-specific size and crop configuration
   - Device-specific capture and export paths

## Cross-platform typography parity

When an Android app has an iOS counterpart, inspect the iOS font registration
and actual font helper implementation before capturing screenshots. Do not
trust a helper name such as `pretendard` without checking the registered family
in `Info.plist`, the font assets, and the SwiftUI `Font.custom` calls.

- Use the same bundled font family and equivalent weight mapping in the
  Android UI and the external screenshot copy when visual parity is the goal.
- Keep regular and bold font files separate. Do not assign one regular font
  file to a variable range of weights, because synthetic or incorrect weights
  change line width and hierarchy.
- Never use a web-only fallback for the final board when the matching app font
  is available locally. Embed the exact local font files in the renderer and
  wait for both regular and bold faces before export.
- If the platforms intentionally use different typography, document the
  difference in the capture config instead of silently mixing font families.

For Boogios apps, a reference iOS app that registers `LINESeedKR-Rg.otf` and
`LINESeedKR-Bd.otf` should use those files as the Android parity source, with a
single canonical family name such as `LINE Seed Sans KR` in Compose and the
screenshot board.
5. Export only after real captures, localized copy, and layout are stable.

## Workflow

1. Identify the Android app, package, source screenshot folder, locales, and
   device categories in scope. Do not assume a repository root or a generated
   Fastlane folder is the source of truth.
2. Inspect the Android app's emulator/device capture tooling and existing asset
   naming scheme before creating new images. The HTML template does not replace
   the app-specific emulator capture step.
3. Choose the device categories intentionally:
   - `phone`
   - `seven-inch` tablet or large-screen portrait/landscape
   - `ten-inch` tablet or large-screen portrait/landscape
   - Wear OS, TV, Automotive OS, Chromebook, or Android XR only when the app
     actually supports that form factor
4. Capture the real app UI from an emulator or device for every requested
   locale whenever possible. Set the emulator/device system language to the
   target Play locale, relaunch the app, and capture the screen from the app
   itself. Do not invent product screens, fake settings, or unsupported
   features in a store screenshot. Use HTML/CSS composition only for permitted
   background, copy, spacing, and layout treatment around truthful UI.
5. Build each locale/device set with stable names such as `01-hero.png`,
   `02-plan.png`, and `03-do.png`. Keep the first three images focused on the
   app's core experience. Do not silently fall back to an English capture when
   a locale capture is missing; report that locale as incomplete.
6. Create one HTML board per screenshot card. Keep the final board size
   pixel-locked for the selected device category, use `object-fit: contain` by
   default so the complete real app capture remains visible, and keep copy
   outside the app capture unless an overlay is explicitly requested. Reuse the
   same `cards` data across locales and swap localized copy and capture paths.
   Do not switch to a crop merely to remove side whitespace; remove artificial
   filler backgrounds instead.
7. Render the HTML boards to PNG using the available browser or Playwright
   capture workflow. Export one image per card into the matching locale/device
   source folder; do not upload the HTML file itself to Play Console.
8. Resize or crop proportionally. Never stretch a screenshot. When changing
   aspect ratio, preserve the complete capture with `contain` by default. Use a
   deliberate crop only when explicitly requested and keep all important UI and
   copy inside the safe area.
9. Flatten screenshots to JPEG or 24-bit PNG without alpha. Keep alpha only
   where the asset type explicitly permits it, such as the 512px app icon.
10. Validate the full asset tree with the bundled validator before upload:

   ```sh
   python3 /path/to/screenshot-android/scripts/validate_google_play_screenshots.py \
     --root android/play/screenshots \
     --require phone=2 \
     --require seven-inch=4 \
     --require ten-inch=4 \
     --icon android/play/assets/app-icon-512.png \
     --feature-graphic android/play/graphics/feature-graphic-1024x500.png
   ```

11. Visually inspect at least one representative image per locale/device set
   with the image viewer. Check text clipping, tiny copy, status-bar noise,
   compression, accidental alpha, complete capture visibility, and consistent
   HTML/CSS composition. Confirm that no artificial background is visible
   inside the capture frame and that all external copy is centered.
12. Copy validated assets into the tracked source folder used by the project,
   then run its metadata/Fastlane sync. Do not edit an ignored generated copy
   if a sync script will overwrite it.
13. For remote replacement, audit the existing Play screenshot sets before
   uploading. Upload only missing or incomplete sets and independently verify
   the remote count/checksums after processing.

## Real capture workflow

Use this when the app can render screenshot-only seed data.

1. Define a stable scenario list first, such as `hero`, `plan`, `editor`, and
   `finished`.
2. Boot the target emulator and build once for that device category.
3. Install the app and launch each scenario with launch arguments or test data.
4. Verify that the device language matches the requested locale before each
   capture. The capture helper should fail on a language mismatch instead of
   producing a mislabeled image.
5. Capture one PNG per scenario with the Android emulator or device capture
   tooling.
6. Store captures per locale and device category, for example:
   - `play/screenshot-design/captures/phone/ko-KR/`
   - `play/screenshot-design/captures/phone/en-US/`
7. Feed those PNGs into the HTML boards.
8. Export one board PNG per card into the matching locale/device directory.

## Locale capture contract

- The capture locale must be produced by the app running with the matching
  Android system language or an explicitly documented in-app language setting.
- Verify the device locale before each capture set and relaunch the app after
  changing it so cached resources cannot leak from the previous locale.
- Never translate, redraw, or overlay app UI text after capture. HTML/CSS may
  localize only the external title and supporting description.
- If Android resources do not exist for a requested locale, stop that locale's
  export and report the missing localization instead of copying an English
  capture into it.
- Regional variants that intentionally share the same language capture, such
  as `en-US` and `en-GB`, must be documented as shared-language captures.

## Device family rules

- `Phone`
  - Keep portrait Google Play board size pixel-locked.
  - Use the actual storefront size for the chosen phone layout.
- `Seven-inch tablet`
  - Prefer a real large-screen emulator capture instead of scaling a phone
    capture up.
  - Keep a separate board layout from phone even if card order and copy stay
    the same.
- `Ten-inch tablet`
  - Choose portrait or landscape intentionally and capture that form factor.
  - Do not manufacture tablet assets from a phone capture when the app layout
    materially changes.

## Device config contract

Keep device sizing, fit mode, and paths in config rather than hardcoding them
into card layout logic.

```js
const device = {
  deviceLabel: "phone",
  boardWidth: 1080,
  boardHeight: 1920,
  imageWidth: 860,
  imageHeight: 1260,
  imageFit: "contain",
  imagePosition: "center",
  imageRadius: 34,
  captureDir: "../captures/phone/ko-KR",
  exportDir: "../screenshots/ko-KR/phone"
};
```

Keep `imageFit: "contain"` and the capture frame background transparent when
the complete app screen must remain visible. Set `imageRadius` explicitly and
apply it directly to the real capture image; use `34px` for the default Android
phone board unless the app's design system requires another value. Only set
`imageFit: "cover"` for an explicitly approved crop; never stretch the real
capture. If the user wants the UI to fill the frame without cropping, change
the frame ratio or accept intentional outer board whitespace rather than
cutting the app screen.

## Reusable structure

```js
const cards = [
  {
    slug: "hero",
    title: "Short localized title",
    body: "One short supporting line",
    image: "/absolute/or/public/path.png",
    alt: "Screen description"
  }
];
```

For multi-device or multi-locale projects:

- reuse the `cards` structure
- swap the localized copy
- swap the device config
- swap capture and export directories

## HTML/CSS board rules

- Keep one board per screenshot and one fixed layout per device category.
- Reuse the same card order across locales and device categories unless the
  storefront target requires a different set.
- Keep app captures truthful and current; never redraw or replace UI in CSS.
- Keep added copy short, localized, and within the board's safe margins.
- Use `contain` for the app capture by default, matching the iOS screenshot
  workflow. Keep the capture wrapper transparent so `contain` does not create a
  fake colored side panel. Use `cover` only when an intentional crop has been
  explicitly reviewed.
- Keep the screenshot area free of decorative backgrounds by default; use a
  transparent image wrapper and let the board background show through only
  when explicitly requested.
- Use a neutral board surface independent from the capture's dominant color so
  the image boundary remains visible.
- Treat the copy block and screenshot as one composition, keeping exactly
  50px between them by default and vertically centering the complete
  composition in the board.
- Apply corner radius directly to the visible screenshot image element, not
  only to an outer placeholder frame, and avoid adding a second card or
  background behind it. When `contain` leaves transparent space in a fixed
  frame, size the image at its natural aspect ratio first and apply the radius
  to that image so its actual corners are rounded.
- For portrait phone captures, do not give the `contain` image element both a
  wide fixed width and a fixed height. That creates an invisible box whose
  shadow or background looks like a second card behind the app screenshot.
  Use `width: auto`, a fixed capture height, and `max-width` instead so the
  visible image keeps its natural aspect ratio. Keep the image wrapper
  transparent and remove shadows or surfaces that belong to the wrapper.
- Keep overflow handling explicit for both title/body copy and cropped images.
- Show only one title and one supporting description outside the app capture by
  default. Remove eyebrows, labels, badges, and extra explanatory text unless
  explicitly requested.
- Center-align the title and description. Do not add terminal periods to store
  screenshot copy.
- Avoid device frames, fingers, fake badges, calls to action, rankings,
  testimonials, pricing claims, and time-sensitive claims.
- For phone boards, use portrait 9:16 output by default. For large screens,
  choose portrait 9:16 or landscape 16:9 intentionally and validate it as the
  corresponding Google Play device category.

## Typography policy

Use a deterministic font family for copy placed outside the real app capture.
The app's own UI must come from the actual emulator/device capture.

If a matching local app font is available, prefer it over a generic system
fallback and declare every weight used by the board explicitly.

| Locale | Title and body family | Notes |
| --- | --- | --- |
| `ko` | `LINE Seed Sans KR`, `Noto Sans KR` | Use the app's bundled family when it is the iOS reference |
| `ja` | `Noto Sans JP`, `Zen Kaku Gothic New` | Keep Japanese tracking at `0` |
| `en-*` | `LINE Seed Sans KR`, `Manrope` | Keep copy short and benefit-led; use the app family when it contains the required Latin glyphs |
| `zh-Hans` | `Noto Sans SC` | Use simplified Chinese glyphs |
| `zh-Hant` | `Noto Sans TC` | Use Taiwan traditional glyphs |
| `th` | `Noto Sans Thai`, `Prompt` | Do not tighten tracking |
| `vi` | `Be Vietnam Pro` | Preserve Vietnamese diacritics |
| `ar` | `Noto Kufi Arabic` | Set RTL direction and `lang="ar"` |
| `hi` | `Noto Sans Devanagari` | Keep natural script proportions |

Keep external screenshot copy centered unless the app-specific design system
intentionally uses another alignment. Do not add manual line breaks,
horizontal scaling, or clipped text to force a fit; shorten the copy or reduce
the font size within the configured minimum instead.

## Current baseline requirements

Use these as a validation baseline, then confirm the current official source:

| Asset | Baseline requirement |
|---|---|
| App icon | 512×512, 32-bit PNG with alpha, max 1 MB |
| Feature graphic | 1024×500, JPEG or 24-bit PNG, no alpha |
| General screenshots | JPEG or 24-bit PNG, no alpha; minimum dimension 320px; maximum dimension 3840px; long side no more than 2× short side |
| Per device category | Up to 8 screenshots |
| Listing minimum | At least 2 screenshots across device types |
| Large screens | At least 4 screenshots for tablet/Chromebook eligibility; 1080–7680px range; 16:9 landscape or 9:16 portrait |
| Promotional-quality recommendation | At least 4 app screenshots at 1080×1920 portrait or 1920×1080 landscape when seeking large-format recommendation surfaces |

Conditional form factors have separate requirements. Do not add Wear OS, TV,
Automotive OS, or XR assets merely to satisfy a count. Validate the app's actual
form-factor distribution and read the relevant official section first.

## Composition rules

- Show the real app interface and current feature set.
- Put the clearest value proposition in the first screenshot without making
  the screenshot look like an advertisement detached from the app.
- Keep added taglines short and readable; do not cover more than roughly 20%
  of the image with text.
- Avoid calls to action, rankings, awards, testimonials, pricing claims,
  Google Play badges, competitor/store badges, or time-sensitive claims.
- Remove notification-bar clutter and personal data from captures.
- Avoid device frames, fingers, unrelated decorative UI, and stretched pixels.
- Localize added copy and graphic text per Play locale; do not translate actual
  app UI in post-processing unless the app itself displays that locale.
- Use alt-text-ready descriptions for every uploaded asset when the workflow
  supports them; describe the meaningful content in 140 characters or fewer.
- Keep feature-graphic focal content centered and away from crop/overlay zones.
- Keep feature-graphic text and other graphic copy localized per Play locale;
  do not reuse one English raster for every locale when translated graphic text
  is part of the design.

## Source and output layout

Prefer a tracked source tree like:

```text
play/
├── assets/app-icon-512.png
├── graphics/feature-graphic-1024x500.png
└── screenshots/
    └── ko-KR/
        ├── phone/01-hero.png
        ├── seven-inch/01-hero.png
        └── ten-inch/01-hero.png
```

For Fastlane supply, sync to a derived tree such as:

```text
fastlane/metadata/android/ko-KR/images/
├── icon.png
├── featureGraphic.png
├── phoneScreenshots/*.png
├── sevenInchScreenshots/*.png
└── tenInchScreenshots/*.png
```

Keep the same locale list across app resources, store metadata, screenshots,
and Fastlane output. Report any intentional shared-language screenshot choice.

Keep HTML/CSS working files beside the screenshot source tree or in a clearly
named local design directory, but keep only flattened, validated PNG/JPEG files
in the Play upload tree. A typical layout is:

```text
play/
├── screenshot-design/
│   ├── google-play-screenshot.html
│   └── captures/
│       ├── phone/
│       └── seven-inch/
└── screenshots/
    └── ko-KR/
        └── phone/01-hero.png
```

## Validator behavior

Use the bundled validator for deterministic checks. It should fail on:

- unsupported image format or alpha in screenshots/feature graphic
- missing required locale/device folder
- fewer than the requested minimum images
- more than 8 images in a device set
- dimensions below the mandatory minimum or above the applicable maximum
- aspect ratio above 2:1 for general screenshots
- large-screen images outside the large-screen size/aspect baseline
- duplicate SHA-256 files inside a locale/device set
- invalid app-icon or feature-graphic dimensions

The validator does not prove that the screenshot depicts the current app, that
the copy is localized correctly, or that Play Console accepted the remote set.
Perform visual and remote verification separately.

## DayBlocks Android reference

When working in a DayBlocks checkout, use these paths after
verifying they still exist:

- source screenshots: `android/play/screenshots/<locale>/phone`,
  `seven-inch`, and `ten-inch`
- source icon: `android/play/assets/app-icon-512.png`
- source feature graphic: `android/play/graphics/feature-graphic-1024x500.png`
- generated Fastlane assets: `android/fastlane/metadata/android/`
- current locales: `de-DE`, `en-AU`, `en-CA`, `en-GB`, `en-US`, `fr-FR`,
  `ja-JP`, `ko-KR`, `zh-CN`, and `zh-TW`

The current DayBlocks source uses six screenshots per locale/device set. Do not
reduce or replace that set without checking the requested release scope.

## Verification report

Report the following after creating or repairing assets:

- source and output directories
- locales and device categories processed
- exact dimensions, format, alpha state, and file counts
- duplicate checksum results
- representative visual checks performed or skipped
- remote Play Console verification performed or still pending
- any generated files left ignored and any tracked source files changed

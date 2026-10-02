---
name: screenshot-ios
description: Use when creating App Store or TestFlight screenshot assets with HTML/CSS, or when real iPhone or iPad simulator captures still need reusable board composition and export.
---

# Screenshot iOS

Use this skill when the user wants store screenshots built from reusable HTML/CSS boards, especially when the final output should combine real simulator captures with editable copy and branding.

## Best fit

- App Store screenshot draft pages
- TestFlight screenshot mockups
- Multi-card screenshot sets with repeated structure
- Reusable screenshot systems shared across apps
- Real simulator captures that still need copy, background, and export framing

## Core workflow

1. Lock the storefront target first.
   - Confirm App Store or TestFlight.
   - Confirm device families: iPhone, iPad, or both.
   - Prefer real simulator captures if the app has stable screenshot seed data.
2. Lock one export size per device family before styling.
   - Keep final board output pixel-locked.
   - Keep capture resolution and board resolution explicit.
3. Keep one board per screenshot.
   - Repeated DOM structure
   - Easy reorder/remove/duplicate
4. Separate content from layout.
   - Shared `cards`
   - Device-specific size config
   - Device-specific capture paths
5. Export only after real captures and copy are stable.

## Real capture workflow

Use this when the app can render screenshot-only seed data.

1. Define a stable scenario list first.
   - Example: `hero`, `plan`, `do`, `see`, `widget`, `pds`
2. Boot the target simulator and build once for that device family.
3. Install the app and launch each scenario with launch arguments or environment flags.
4. Capture one PNG per scenario with `xcrun simctl io screenshot`.
5. Store captures per device family.
   - Example:
     - `fastlane/screenshots/captures/iphone/`
     - `fastlane/screenshots/captures/ipad13/`
6. Feed those PNGs into HTML boards.
7. Export one board PNG per card into matching device-family export directories.

## Device family rules

- `iPhone`
  - Keep portrait App Store board size pixel-locked.
  - Use the actual storefront size for the chosen phone family.
- `Large iPad`
  - Prefer a real large-screen simulator capture instead of scaling phone captures up.
  - `iPad Air 13-inch` is a good default when it is locally available.
  - Keep a separate board layout from iPhone even if the card order and copy stay the same.

## Device config contract

Keep device sizing in config, not hardcoded into card layout logic.

```js
const device = {
  deviceLabel: "ipad13",
  boardWidth: 2048,
  boardHeight: 2732,
  imageWidth: 1820,
  imageHeight: 1980,
  captureDir: "../captures/ipad13",
  exportDir: "../export/ipad13"
}
```

Recommended split:

- `cards`: shared slug/title/body order
- `device`: board and image sizing
- `image paths`: resolved from `device.captureDir`

## Reusable structure

```js
const cards = [
  {
    slug: "hero",
    title: "Short title",
    body: "One short support line",
    image: "/absolute/or/public/path.png",
    alt: "Screen description"
  }
]
```

For multi-device projects:

- reuse `cards`
- swap `device`
- swap capture directory
- swap export directory

## Layout rules

- Prefer simple top-to-bottom boards unless the user asks for a more editorial composition.
- Keep text outside the screenshot unless an overlay is explicitly desired.
- Use one visual system per app.
- Use `object-fit: contain` by default for real captures.
- Keep the screenshot area free of decorative backgrounds by default; use a
  transparent image wrapper and let the board background show through only
  when explicitly requested.
- Use a neutral board surface that is intentionally independent from the
  screenshot's own dominant background color so the image boundary and corner
  radius remain visible.
- Treat the copy block and screenshot as one composition, keep exactly 50px
  between them by default, and vertically center that complete composition in
  the board.
- Apply corner radius directly to the screenshot image element and avoid
  adding a second card or background behind it.
- Keep overflow handling explicit for both title and body.

## Typography policy

Use the following font policy for copy placed outside the real app capture on
App Store and TestFlight boards. The font family applies to both the title and
supporting description unless the app-specific design system explicitly
requires a different treatment inside the captured app UI.

| Locale | Title and body family | Notes |
| --- | --- | --- |
| `ko` | `LINE Seed KR`, `Noto Sans KR` | Korean-first, clean and friendly tone |
| `ja` | `LINE Seed JP`, `Zen Kaku Gothic New`, `Noto Sans JP` | Keep Japanese tracking at `0` |
| `en-*` | `LINE Seed EN`, `Manrope` | Keep copy short and benefit-led |
| `zh-Hans` | `Noto Sans SC` | Use simplified Chinese glyphs |
| `zh-Hant` | `Chiron GoRound TC`, `Noto Sans TC` | Use Taiwan traditional glyphs |
| `th` | `LINE Seed TH`, `Prompt`, `Noto Sans Thai` | Do not tighten tracking |
| `vi` | `Be Vietnam Pro` | Preserve Vietnamese diacritics |
| `ar` | `Noto Kufi Arabic` | Set RTL direction and `lang="ar"` |
| `hi` | `Noto Sans Devanagari` | Keep the natural script proportions |

For Korean App Store boards, load `Noto Sans KR` as the deterministic web
fallback when `LINE Seed KR` is not installed locally. Do not silently fall
back to an unspecified system font during export. Wait for the selected web
font to finish loading before measuring or exporting text.

Keep the external screenshot copy centered. Use one title line and one
supporting-description line per board whenever the storefront layout allows
it. Do not add manual line breaks, ellipses, horizontal scaling, or clipped
text to force a fit; shorten the copy or reduce the font size within the
configured minimum instead.

For the default App Store board, keep the composition to exactly three parts:
one title, one supporting description, and one real app screenshot. Do not add
eyebrows, badges, taglines, footer copy, logos, decorative labels, or extra
marketing phrases unless the user explicitly requests them.

## Export-friendly implementation guidance

- Give each board a fixed width and height for the final submission size.
- Keep a separate fixed layout per device family.
- Use wrappers such as:
  - `.screenshot-board`
  - `.screenshot-copy`
  - `.screenshot-device-image`
- If real screenshots must remain fully visible, use `contain`.
- Use `cover` only when cropping is intentional.

## Browser and export workflow

1. Create or refresh the real simulator captures first.
2. Build the preview board.
3. Verify:
   - copy hierarchy
   - clipping
   - image scaling
   - safe margins
4. Export one PNG per board.
5. Keep outputs grouped by device family.

## Deliverables

When using this skill, prefer producing:

- Real simulator PNG captures when the app supports seeded screenshots
- A reusable HTML preview page
- Matching CSS or inline style system
- Config-driven screenshot boards
- Export-ready PNG outputs grouped by device family

## Included template

Start from:

- `assets/app-store-screenshot-template.html`

Adapt:

- board size
- card copy
- screenshot paths
- branding
- device config
- capture/export directory structure

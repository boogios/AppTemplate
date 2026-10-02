# Google Play Preview Asset Reference

Primary source: [Add preview assets to showcase your app](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en)

This reference is a working baseline, not a substitute for checking the live
Google Play Help page before a release. Requirements can vary by form factor and
Google may update them.

## Main listing assets

- App icon: 32-bit PNG with alpha, 512×512px, maximum 1 MB.
- Feature graphic: JPEG or 24-bit PNG without alpha, 1024×500px.
- Screenshots: JPEG or 24-bit PNG without alpha; up to 8 per supported device
  type.

## General screenshot constraints

- Minimum dimension: 320px.
- Maximum dimension: 3840px.
- Maximum dimension must not be more than twice the minimum dimension.
- At least two screenshots across different device types are required to
  publish a store listing.

## Large screens

For tablets and Chromebooks, Google currently describes a minimum of four
screenshots for large-screen presentation, with images between 1080px and
7680px and a 16:9 landscape or 9:16 portrait aspect ratio.

For app recommendation surfaces, Google recommends at least four app
screenshots at 1080×1920 portrait or 1920×1080 landscape. Treat this as a
promotion-quality recommendation, not a replacement for the mandatory general
constraints.

## Conditional categories

- Wear OS: at least one accurate app screenshot, 1:1, minimum 384×384px, with
  the app interface only.
- Android TV: at least one TV screenshot and a 1280×720 banner are required
  for TV-enabled distribution.
- Android Automotive OS: requirements depend on the app category; supported
  apps may need at least two 800×1280 portrait and two 1024×768 landscape
  screenshots.
- Android XR: 4–8 screenshots, 8:5 aspect ratio, up to 8 MB each; Google
  recommends 3840×2400 and requires at least 1920×1200.

Always verify the exact current section before generating conditional assets.

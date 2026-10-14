# SnapSort

<img src="docs/icon.png" width="96" align="right">

**Your screenshots, sorted.** A small Android app, written in Kotlin with
Jetpack Compose, that reads your phone's Screenshots folder and organizes it.
No AI and no internet permission: everything stays on the phone. The whole app
is about 1.6 MB.

<p>
  <img src="docs/screenshots/timeline.png" width="200">
  <img src="docs/screenshots/apps.png" width="200">
  <img src="docs/screenshots/albums.png" width="200">
  <img src="docs/screenshots/cleanup.png" width="200">
</p>

<p>
  <img src="docs/screenshots/onboarding-1.png" width="160">
  <img src="docs/screenshots/onboarding-2.png" width="160">
  <img src="docs/screenshots/swipe.png" width="160">
  <img src="docs/screenshots/selecting.png" width="160">
  <img src="docs/screenshots/viewer.png" width="160">
  <img src="docs/screenshots/timeline-dark.png" width="160">
</p>

## Design

A warm, editorial look that matches the app icon.

- **Type:** Plus Jakarta Sans for the interface, with Instrument Serif italic for
  the accent word in each big title ("Your *screenshots.*", "Clean *up.*").
  Both are bundled (trimmed to Latin) in `app/src/main/res/font` under the SIL
  Open Font License.
- **Colour:** a warm off-white page (near-black in dark mode), violet and coral
  from the icon, and a stable colour per app (WhatsApp green, Chrome blue…).
  Flat colours only: no gradients and no emoji anywhere.
- **Shapes:** very rounded cards, white circle buttons, and fanned stacks of
  screenshots, the icon's motif, on every app and album card.
- **Navigation:** a floating dark pill. The current tab grows into a labelled
  white pill. While you select screenshots, it slides away for a dock with
  Album, Share, Favorite and Delete.
- **Viewer:** a full-screen view with glass controls. Pinch or double-tap to zoom, swipe sideways for the next one, swipe
  down to close.
- **Motion:** staggered entrances, springy press feedback,
  numbers that count up, and haptics on selection.
- **Onboarding:** three full-bleed pages with animated art built from sample
  screenshots, ending with the photo permission request.

Design tokens, type and colours live in `ui/Theme.kt`, shared pieces in
`ui/Components.kt`. Light, dark or system theme is set in Settings
(the slider button on the Timeline).

## Features

- **Timeline:** a "Latest" rail of big cards, filter pills for your top apps,
  search (app, file name or month), and a grid grouped into Today / Yesterday /
  This week / months.
- **Apps:** screenshots grouped by the app they were taken in, sorted by most,
  biggest or A–Z. The app is read from the file name, which phone makers fill in
  differently:
  - Samsung / Pixel: `Screenshot_20240115-093012_WhatsApp.jpg`
  - Xiaomi: `Screenshot_2024-01-15-09-30-12-345_com.whatsapp.jpg` (the package
    name, turned into the app's real name)
  - Oppo / OnePlus: `Screenshot_…_<md5 of package>.jpg` (matched against
    installed apps)
  - or a `Screenshots/<App>/` subfolder

  When the name doesn't say, and Usage access is on, SnapSort looks up the app
  that came to the front just before the screenshot's timestamp in Android's
  usage history (`UsageResolver.kt`). That's exact, not a guess. Android keeps
  that history for about a week, so answers are saved, and a platform
  job (`LabelJob.kt`) labels new screenshots twice a day. Anything older can be
  filed by hand with **Set app**, which always wins.

  Still unknown? SnapSort recognises the app from the picture itself, with fixed
  rules and no AI (`data/Look.kt`). Each screenshot is shrunk once to
  24 × 52 pixels (`LookStore.kt`) and checked against:
  - built-in fingerprints for apps with unmistakable colours and layouts
    (WhatsApp's wallpaper with green sent messages on the right, Telegram,
    Spotify, Snapchat, Viber), and
  - the person's own screenshots whose app is known: it takes the app only if
    the three closest look-alikes all agree and are very close.

  The same picture always gets the same answer, and when unsure it stays in
  Other. `LookTest` checks the rules on the sample screens: no false
  matches, and the look-alike matcher is never wrong when holding each one out.

  Order: your choice, then the file name, then usage history, then how it
  looks, then Other.
- **Albums:** Favorites plus your own albums. Long-press screenshots to select
  them, then add them to an album, share or delete. Long-press an album to
  rename or delete it.
- **Swipe to clean:** go through screenshots one card at a time, Tinder style:
  swipe left to delete, right to keep, up to favorite, with undo. Deletions are
  collected and done together at the end, after a summary, so Android asks only
  once. Kept screenshots are remembered, so the next session picks up where you
  left off. Start it from Clean up, or from any app's page to sweep through just
  that app.
- **Clean up:** how much space screenshots take, split by app; an exact
  duplicate finder that keeps the oldest copy; old screenshots (30 days,
  3 months or 1 year); and the biggest files. On Android 11+ deletes go to the
  system recycle bin, where they can be restored for 30 days.

## Run

Needs JDK 17 and the Android SDK (platform 36).

```sh
./gradlew :app:testDebugUnitTest    # unit tests: file-name parser, look rules, formatting
./gradlew :app:installDebug         # on a connected phone
./gradlew :app:assembleRelease      # app/build/outputs/apk/release/app-release.apk
```

Release builds are shrunk with R8 and signed with the key in `key.properties`
(not committed). Without it they fall back to the debug key.
`scripts/setup-signing.sh` recreates it from the `ANDROID_KEYSTORE_*` secrets.

Updating from the Flutter versions (1.x) keeps albums, favourites and choices:
`Store.kt` copies them over on first launch.

## Releases

Push a tag that matches `versionName` in `app/build.gradle.kts` (for example `v1.2.0`), or
run Actions > Release > Run workflow. It runs the checks, builds the signed APK,
verifies the signing key's fingerprint and publishes the Release with the APK
and a checksum. It needs the repository secrets `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_ALIAS`.

## Banners

<p>
  <img src="docs/banners/01-hello.png" width="200">
  <img src="docs/banners/02-by-app.png" width="200">
  <img src="docs/banners/03-no-ai.png" width="200">
  <img src="docs/banners/05-clean-up.png" width="200">
</p>

Eight 2160 × 2160 banners in `docs/banners`, built from `tool/banners/banners.html`
around real renders of the app:

```sh
node tool/banners/render.cjs   # needs `playwright`
```

The sample screenshots used in onboarding, the tests and the banners come from
`node tool/demo/render.cjs`.

## Icon

The launcher icon is drawn in code by `design/icon/gen_icon.py` (Android vector
drawables plus `icon.svg`); `node design/icon/render.cjs` renders the PNGs. The
launch screen reuses the same vector drawables.

## Structure

```
app/src/main/java/com/kidyoh/snapsort/
  MainActivity.kt   permissions, recycle bin, share; the Application holds the library
  LabelJob.kt       twice-daily usage-history labelling (JobScheduler)
  data/             Shot model, Library state, file-name parser, look rules,
                    MediaStore reader, usage history, thumbnails, saved state
  ui/               theme, components, sheets, nav, shot grid, actions
  ui/screens/       shell, timeline, apps, albums, clean up, group page,
                    swipe to clean, viewer, settings, onboarding
```

<p align="center"><img src="docs/icon.png" width="128" alt="SnapSort icon"></p>

# SnapSort

**Your screenshots, sorted.** A Flutter app for Android that reads your phone's
Screenshots folder and organizes it. No AI, no internet permission — everything
stays on the phone.

## What it does

- **Timeline** – every screenshot, newest first, grouped into Today / Yesterday /
  This week / months. Quick filter chips for your top apps and search by app,
  file name or month.
- **Apps** – screenshots grouped by the app they were taken in. The app is read
  from the file name, which phone makers fill in differently:
  - Samsung / Pixel: `Screenshot_20240115-093012_WhatsApp.jpg`
  - Xiaomi: `Screenshot_2024-01-15-09-30-12-345_com.whatsapp.jpg` (package name,
    turned into the app's real name)
  - Oppo / OnePlus: `Screenshot_…_<md5 of package>.jpg` (matched against
    installed apps)
  - or a `Screenshots/<App>/` subfolder
- **Albums** – Favorites plus your own albums ("Receipts", "Memes"…).
  Long-press to multi-select, then add to an album, share or delete.
- **Clean up** – storage summary, byte-for-byte duplicate finder, old
  screenshots (30 days / 3 months / 1 year), biggest files and space per app.
  On Android 11+ deletes go to the system recycle bin (recoverable for 30 days).
- **Viewer** – swipe between screenshots, pinch / double-tap to zoom,
  favorite, add to album, share, open in another app, details.

## Building

```sh
flutter pub get
flutter test
flutter build apk --release
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`.

Release builds are signed with the key described in `android/key.properties`
(not committed):

```properties
storePassword=…
keyPassword=…
keyAlias=snapsort
storeFile=../snapsort-release.jks
```

Without that file the release build is signed with the debug key.

## Code layout

| Path | What |
| --- | --- |
| `lib/data/app_name.dart` | File name → source app parser (unit tested) |
| `lib/data/library.dart` | App state: screenshots, app groups, albums, duplicate scan |
| `lib/data/media_channel.dart` | Dart side of the native channel |
| `android/app/src/main/kotlin/…/MainActivity.kt` | MediaStore query, recycle bin, share, app names, hashing |
| `lib/ui/` | Screens: timeline, apps, albums, clean up, viewer, welcome |

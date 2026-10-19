# SnapSort on Google Play: everything to paste

Package name: **com.kidyoh.snapsort**
Version: **2.0.0** (version code 2009)
Upload: `snapsort-2.0.0.aab`, signed with the SnapSort release key
(SHA-1 `A2:C4:40:3B:63:83:C6:07:82:70:1B:D4:38:5E:18:F0:8F:D6:67:15`)

---

## 1. Create app

| Field | Answer |
|---|---|
| App name | SnapSort: Screenshot Organizer |
| Default language | English (United States) – en-US |
| App or game | App |
| Free or paid | Free |
| Declarations | Tick both (Developer Program Policies, US export laws) |

## 2. App signing (do this before the first upload)

Choose **Use a different key → Export and upload a key from Java keystore**.
Play shows a command with its own encryption key; it looks like this:

```sh
java -jar pepk.jar --keystore=snapsort-release.jks --alias=snapsort \
  --output=snapsort-signing-key.zip --include-cert --rsa-aes-encryption \
  --encryption-key-path=encryption_public_key.pem
```

Use the store and key password from `key.properties`. Upload the zip.
This keeps the same signature as the APKs on GitHub, so people who
sideloaded SnapSort can update from Play without losing their albums.
Don't let Google generate a new key.

## 3. Store listing (Grow → Store presence → Main store listing)

**App name** (30 max)
```
SnapSort: Screenshot Organizer
```

**Short description** (80 max)
```
Sort screenshots by app, clear duplicates and clean up. No AI, no internet.
```

**Full description** (4000 max)
```
Your phone's Screenshots folder, finally tidy.

SnapSort reads the screenshots already on your phone and organises them for you. It has no account, no ads, no AI and no internet permission, so your screenshots never leave your phone.

SORTED BY APP
WhatsApp chats, receipts, maps, recipes and memes each get their own pile. SnapSort reads the app from the file name your phone already writes, and when the name doesn't say, it can look up which app was open at the moment you took the screenshot (optional Usage access). It can also recognise popular apps from how the screenshot looks, using fixed rules. You can always pick the app yourself.

A TIMELINE THAT MAKES SENSE
Your newest screenshots up front, then Today, Yesterday, This week and every month after. Filter by app or search by app, file name or month.

SWIPE TO CLEAN
Go through your screenshots one card at a time: swipe left to delete, right to keep, up to favourite, with undo. Everything you mark is deleted together at the end, after a summary.

CLEAN UP IN A TAP
See how much space screenshots take, split by app. Find exact duplicates, old screenshots and the biggest files, and clear them out. On Android 11 and later, deleted screenshots go to the system trash, where you can restore them for 30 days.

ALBUMS AND FAVOURITES
Keep the screenshots that matter: tap the heart, or long-press to add a batch to your own albums.

SMALL AND PRIVATE
Under 2 MB, works offline, and has no internet permission. Your favourites and albums stay on your phone.

Made with care, with a light and dark theme.
```

**Graphics**
- App icon: `icon-512.png` (512 × 512)
- Feature graphic: `feature-graphic.png` (1024 × 500)
- Phone screenshots (upload in this order): `01-hello.png`, `02-by-app.png`,
  `03-no-ai.png`, `04-find-it.png`, `05-clean-up.png`, `06-albums.png`,
  `07-private.png` (2160 × 2160 each)

**Contact details** (Store settings)
- Email: kidyoh789@gmail.com
- Website: https://kidus.pro.et
- Privacy policy: https://kidus.pro.et/privacy/snapsort/

**Category**: Apps → Photography
**Tags**: Photo gallery, Productivity, Tools (pick what Play offers closest)

## 4. App content (Policy → App content)

**Privacy policy**
```
https://kidus.pro.et/privacy/snapsort/
```

**Ads**: No, my app does not contain ads.

**App access**: All functionality is available without special access.
Optional note for reviewers:
```
No login. On first launch, allow photo access. Usage access is optional: Settings (slider icon on the Timeline) > Turn on usage access. It is only used to label screenshots whose file name doesn't say which app they came from.
```

**Content rating** (IARC questionnaire)
- Email: kidyoh789@gmail.com
- Category: All other app types (utility / productivity)
- Violence, fear, sexuality, language, controlled substances, gambling: **No** to all
- Users can interact or exchange content: **No**
- Shares user's location: **No**
- Allows purchases of digital goods: **No**
- Expected result: Everyone / PEGI 3

**Target audience and content**
- Age groups: **13–15, 16–17, 18 and over** (not under 13; the app isn't aimed at children)
- Could the app unintentionally appeal to children: **No**

**News app**: No
**COVID-19 contact tracing / status**: No
**Government app**: No
**Financial features**: My app doesn't provide any financial features
**Health**: My app does not have any health features

**Data safety**
- Does your app collect or share any of the required user data types? **No**
  (Everything SnapSort reads is processed on the phone and never sent off it.
  There is no internet permission. Shares only happen when the person taps
  Share and picks an app, which Play doesn't count as the app sharing data.)
- Is all of the user data collected by your app encrypted in transit? Not asked
  once you answer No above.
- Do you provide a way for users to request that their data is deleted? Not asked.

**Photo and video permissions** (READ_MEDIA_IMAGES)
- Core use: **Photo organiser / gallery-type app**
- Description:
```
SnapSort is a screenshot organiser. Its core feature is reading every image in the phone's Screenshots folders to group them by app, show them in a timeline, find exact duplicates and old or large files, and let the person delete the ones they don't need. This needs ongoing access to all screenshots, including new ones, which the one-time system photo picker can't provide. Nothing is uploaded: the app has no internet permission.
```

**Usage access (PACKAGE_USAGE_STATS)**, if review asks:
```
Optional and off by default. The person turns it on in Android settings from a clearly labelled card. SnapSort reads only which app came to the foreground at the moment each screenshot was taken, to label screenshots whose file name doesn't include the app. The result (screenshot -> app) stays on the phone; nothing is sent anywhere.
```

## 5. Testing and release

New personal developer accounts must run a **closed test with at least 12
testers for 14 days** before applying for production. Steps:
1. Testing → Closed testing → Create track → upload `snapsort-2.0.0.aab`.
2. Add testers (an email list or a Google Group) and share the opt-in link.
3. After 14 days with 12+ opted-in testers, apply for production access, then
   promote the release to Production.

**Release name**: `2.0.0`
**Release notes** (500 max)
```
<en-US>
SnapSort is now a small native app, under 2 MB. Sort screenshots by app, swipe to clean, find duplicates, old and big files, and keep favourites and albums. No AI, no ads, no internet permission.
</en-US>
```

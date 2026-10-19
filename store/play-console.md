# SnapSort on Google Play: the full guide

Everything you need, in order, from where you are now to the public launch.
Text inside grey boxes is ready to copy and paste.

**Your app at a glance**

| | |
|---|---|
| Package name | `com.kidyoh.snapsort` |
| App name | SnapSort: Screenshot Organizer |
| Version | 2.0.0 (version code 2009) |
| File to upload | `snapsort-2.0.0.aab` |
| Signing key SHA-256 | `38:A1:41:BF:DC:7C:30:71:5C:8C:9D:7C:53:F0:F1:5B:AA:40:3B:A1:15:7F:92:2F:B7:24:89:17:FE:47:BC:2D` |
| Signing key SHA-1 | `A2:C4:40:3B:63:83:C6:07:82:70:1B:D4:38:5E:18:F0:8F:D6:67:15` |
| Privacy policy | https://kidus.pro.et/privacy/snapsort/ |
| Contact email | kidyoh789@gmail.com |
| Website | https://kidus.pro.et |

**The road map**

1. Register the package name (done: you uploaded the ownership APK)
2. Create the app in Play Console
3. Fill in the App content forms
4. Fill in the store listing and graphics
5. Make a tester group
6. Create the closed test release (with app signing) and send it for review
7. Get 12 testers in, then wait 14 days
8. Apply for production
9. Publish to everyone
10. Later updates

How long it takes: setup is an afternoon. Then review (usually 1 to 7 days),
then 14 days of testing, then the production review (usually a few days).
Plan for about 3 to 4 weeks in total.

---

## Step 1. Register the package name

You've uploaded `snapsort-ownership.apk` on the "Sign and upload an APK"
screen. Google checks it automatically. If it says the snippet doesn't match,
copy the snippet with its copy button, send it to Claude, and upload the new
APK it builds.

You don't have to wait for this to finish before doing steps 2 to 5.

---

## Step 2. Create the app

Play Console home → **Create app**.

| Field | Answer |
|---|---|
| App name | `SnapSort: Screenshot Organizer` |
| Default language | English (United States) – en-US |
| App or game | App |
| Free or paid | Free (you can never change a free app to paid later) |
| Declarations | Tick both boxes (Developer Program Policies, US export laws) |

Click **Create app**. You land on the app's **Dashboard**, which lists the
setup tasks below. Each one has a "Start" or "Go to" link.

---

## Step 3. App content forms

Left menu → **Policy and programs → App content** (or follow the Dashboard
links). Do each section, then click **Save** at the bottom.

### 3.1 Privacy policy
```
https://kidus.pro.et/privacy/snapsort/
```

### 3.2 App access
Choose **All functionality in my app is available without any access
restrictions**. If Play asks for instructions anyway, paste:
```
No login or account. On first launch, allow photo access. Usage access is optional: open Settings (slider icon at the top of the Timeline) and tap "Turn on usage access". It is only used to label screenshots whose file name doesn't say which app they came from.
```

### 3.3 Ads
**No, my app does not contain ads.**

### 3.4 Content rating
Click **Start questionnaire**.
- Email address: `kidyoh789@gmail.com`
- Category: **All other app types**
- Answer **No** to everything: violence, fear, sexuality, language, controlled
  substances, gambling, crude humour, user interaction or content sharing,
  sharing the user's location, buying digital goods, unrestricted internet.
- Save → **Next** → **Submit**.

You should get Everyone / PEGI 3 / USK 0.

### 3.5 Target audience and content
- Target age groups: tick **13–15**, **16–17** and **18 and over**. Don't tick
  anything under 13 (that brings in the stricter Families rules, and the app
  isn't made for children).
- Could your store listing unintentionally appeal to children? **No**.

### 3.6 News apps
**No**.

### 3.7 COVID-19 contact tracing and status apps
**My app is not a publicly available COVID-19 contact tracing or status app.**

### 3.8 Data safety
1. Overview: read it, click **Next**.
2. **Does your app collect or share any of the required user data types?**
   **No.** Click Next.
   (Why No is correct: SnapSort processes everything on the phone, has no
   internet permission and never sends data anywhere. When the person taps
   Share and picks an app, Play doesn't count that as the app sharing data.)
3. Preview the summary ("No data collected, No data shared") → **Submit**.

### 3.9 Government apps
**No**.

### 3.10 Financial features
**My app doesn't provide any financial features.**

### 3.11 Health apps
**My app does not have any health features** (or tick nothing and save).

### 3.12 Photo and video permissions
This appears after the first upload (step 6), because Play sees the
READ_MEDIA_IMAGES permission in the app.
- Core use: **Photo organiser / gallery-type app** (pick the closest option).
- Description:
```
SnapSort is a screenshot organiser. Its core feature is reading every image in the phone's Screenshots folders to group them by app, show them in a timeline, find exact duplicates and old or large files, and let the person delete the ones they don't need. This needs ongoing access to all screenshots, including new ones, which the one-time system photo picker can't provide. Nothing is uploaded: the app has no internet permission.
```
- If it asks for a video, record your screen for 20 to 30 seconds: open
  SnapSort, show the Timeline, the Apps tab and Clean up. Upload it to YouTube
  as Unlisted and paste the link.

### 3.13 Usage access (only if Play asks)
SnapSort uses the optional Usage access permission. There's normally no form
for it, but if review asks about it, reply:
```
Usage access is optional and off by default. The person turns it on in Android settings from a clearly labelled card in the app. SnapSort reads only which app came to the foreground at the moment each screenshot was taken, to label screenshots whose file name doesn't include the app. The result (screenshot -> app name) stays on the phone; nothing is sent anywhere. The app has no internet permission.
```

---

## Step 4. Store listing and graphics

### 4.1 Main store listing
Left menu → **Grow users → Store presence → Main store listing**.

**App name** (30 characters max, this one is exactly 30)
```
SnapSort: Screenshot Organizer
```

**Short description** (80 max, this one is 75)
```
Sort screenshots by app, clear duplicates and clean up. No AI, no internet.
```

**Full description** (4000 max, this one is about 1600)
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

**Graphics** (all in the zip)

| Slot | File |
|---|---|
| App icon (512 × 512) | `icon-512.png` |
| Feature graphic (1024 × 500) | `feature-graphic.png` |
| Phone screenshots (2 to 8) | all 8 files in `screenshots/` (`01-timeline.png` to `08-dark.png`, 1080 × 1920), in that order |
| Tablet screenshots | Leave empty (optional) |
| Video | Leave empty (optional) |

Click **Save**.

### 4.2 Store settings
Left menu → **Grow users → Store presence → Store settings**.
- App category: **Photography**
- Tags: pick up to 5 close ones, e.g. Photo gallery, Productivity, Tools
- Email address: `kidyoh789@gmail.com`
- Website: `https://kidus.pro.et`
- Phone: optional, leave empty

Click **Save**.

---

## Step 5. Make a tester group (no need to collect emails)

1. Open https://groups.google.com → **Create group**.
   - Name: `SnapSort testers`
   - Group email: `snapsort-testers` (becomes `snapsort-testers@googlegroups.com`;
     if it's taken, try `snapsort-testers-kidyoh`)
2. Privacy settings:
   - Who can search for group: **Anyone on the web**
   - Who can join group: **Anyone can join**
   - Who can view conversations: **Group members**
   - Who can post: **Group managers** (keeps it quiet)
3. Create the group and copy its link
   (https://groups.google.com/g/snapsort-testers).

Testers join the group with one tap. You never need their email addresses.

---

## Step 6. Closed test release

Left menu → **Test and release → Testing → Closed testing**.
There's usually a ready-made track called "Closed testing" or "Alpha".
Click **Manage track** (or **Create track** and name it `Testers`).

### 6.1 Countries
**Countries / regions** tab → **Add countries / regions** → select all, or at
least the countries your testers live in (for example Ethiopia, plus anywhere
your friends are). Save.

### 6.2 Testers
**Testers** tab:
- Choose **Google Groups** and enter `snapsort-testers@googlegroups.com`.
- Feedback URL or email address: `kidyoh789@gmail.com`
- Save. The **opt-in link** appears on this page once the release is
  available. Copy it for step 7.

### 6.3 Create the release
**Releases** tab → **Create new release**.

**a. App signing (first time only).** Play asks how the app will be signed.
- Choose **Use a different key** (or "Change app signing key") →
  **Export and upload a key from Java keystore**.
- Play shows a download for its encryption public key
  (`encryption_public_key.pem`) and a `pepk.jar` command.
- Send that `.pem` file (or its text) to Claude. Claude runs the command on
  the SnapSort key and sends back `snapsort-signing-key.zip`, which only
  Google can decrypt.
- Upload that zip where Play asks, and save.
- **Don't choose "Let Google generate a key".** People who installed SnapSort
  from GitHub could then never update from Play without uninstalling and
  losing their albums.

**b. App bundle.** Drag in `snapsort-2.0.0.aab`.

**c. Release details.**
- Release name: `2.0.0`
- Release notes:
```
<en-US>
SnapSort is now a small native app, under 2 MB. Sort screenshots by app, swipe to clean, find duplicates, old and big files, and keep favourites and albums. No AI, no ads, no internet permission.
</en-US>
```

**d.** Click **Next**. Fix any errors it lists (warnings are fine), then
**Save**.

### 6.4 Send for review
Left menu → **Publishing overview** → **Send changes for review** → confirm.
The first review usually takes 1 to 7 days. You'll get an email.

---

## Step 7. Testers and the 14 days

Once the review email says it's approved:

1. Send testers both links (message below).
2. Check **Closed testing → Testers** to see how many have opted in.
3. The 14 days count only while **at least 12 testers are opted in**. Ask
   people to stay in and keep the app installed for the whole two weeks.
   Add a couple of extra testers in case some drop out.
4. Ask testers to actually open the app a few times. Google asks about
   testing activity when you apply for production.

Message to send (Telegram, WhatsApp):
```
I'm launching my app SnapSort on the Play Store. It sorts your screenshots by app and helps you clean them up. No ads, no internet.

Google needs 12 testers for 14 days. Could you help? It takes 1 minute:
1. Join the testers group: <group link>
2. Open this and tap "Become a tester": <Play opt-in link>
3. Install SnapSort from the Play Store link on that page.
4. Keep it installed for 2 weeks, and open it now and then.

If anything looks wrong, tell me. Thank you!
```

Where to find testers: friends and family, your friend with the Samsung A10
(also a real-phone test), and communities where developers test each other's
apps, such as r/AndroidClosedTesting on Reddit.

Use the two weeks to collect feedback. If someone finds a bug, Claude can fix
it and build version 2.0.1. Upload it to the same closed track as a new
release.

---

## Step 8. Apply for production

After 14 days with 12+ testers, the Dashboard shows **Apply for production**.
Google asks a few questions. Suggested answers (edit to match what really
happened):

**How did you recruit testers?**
```
Friends, family and people from Android developer communities. They joined through a Google Group and the Play opt-in link.
```

**How easy was it to recruit testers?** Pick the honest option.

**Describe how testers engaged with your app.**
```
Testers used SnapSort on their own phones with their real screenshots: browsing the timeline, grouping by app, using Swipe to clean to delete screenshots, scanning for duplicates and making albums. They tested on several phones, including an older Samsung Galaxy A10.
```

**Summarise the feedback you received and how you acted on it.** Write what
testers said and any fixes, for example:
```
Testers liked the swipe-to-clean flow and the size of the app. Feedback included <what they reported>; we fixed it in version <x>.
```

**Who is the intended audience?**
```
Anyone with a lot of screenshots on their Android phone who wants them sorted by app and cleaned up, without uploading anything or using AI.
```

**How does your app provide value to users?**
```
Phones save hundreds of screenshots into one folder. SnapSort groups them by app automatically, shows a clean timeline, and makes it quick to free up space by deleting duplicates, old and large screenshots or swiping through them, all offline and private.
```

**Expected installs in the first year:** pick a realistic range, e.g. 0–10K.

**Is the app ready for production?** **Yes**, and mention any changes made
during testing.

Submit. Google usually answers within about 7 days.

---

## Step 9. Publish to everyone

When production access is approved:
1. **Test and release → Production → Countries / regions** → add all
   countries (or the ones you want).
2. **Production → Create new release** → **Add from library** → pick the
   tested `2.0.0` bundle (or the latest one) → same release notes → **Next →
   Save**.
3. **Publishing overview → Send changes for review.**
4. After approval, SnapSort is live at
   https://play.google.com/store/apps/details?id=com.kidyoh.snapsort

Tip: you can start with a **staged rollout** (for example 20%) and raise it to
100% after a day or two if nothing breaks.

---

## Step 10. Later updates

1. Ask Claude for the change. Every new build gets a higher version code
   (2010, 2011, …) and the same signing key.
2. Upload the new `.aab` to the track you want (closed testing first, or
   straight to production once you're live).
3. Write short release notes, Save, Send for review.

---

## Keep the signing key safe

The SnapSort key (`snapsort-release.jks` plus its passwords in
`key.properties`) signs every version: GitHub APKs and Play uploads. If it's
lost, the app can't be updated outside Play, and you'd need Google's help to
reset the upload key. Ask Claude for a backup copy and keep it in a password
manager or another private, safe place. Never put it in a public repository.

---

## If something goes wrong

| Problem | What to do |
|---|---|
| "Package name already in use" or "not registered" when uploading | Wait for the ownership check (step 1) to finish, then upload again. |
| "You uploaded an APK or bundle signed with the wrong key" | You probably chose a different signing option. Send Claude a screenshot. |
| "Version code 2009 has already been used" | Ask Claude for a new build with a higher version code. |
| Rejected for the photo permission | Reply with the text in 3.12 and add the short screen recording. |
| Asked about Usage access | Reply with the text in 3.13. |
| Not enough testers after 14 days | Keep inviting; the clock continues once you reach 12 again. |
| Any other rejection email | Copy the whole email to Claude for the exact fix. |

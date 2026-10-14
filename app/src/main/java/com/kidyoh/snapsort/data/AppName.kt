package com.kidyoh.snapsort.data

/*
 * Works out which app a screenshot was taken in, purely from its file name
 * and folder. Phone makers bake this into the name in a few different ways:
 *
 *   Samsung / Pixel:  Screenshot_20240115-093012_WhatsApp.jpg
 *   Xiaomi (MIUI):    Screenshot_2024-01-15-09-30-12-345_com.whatsapp.jpg
 *   Oppo / OnePlus:   Screenshot_2024-01-15-09-30-12-34_{md5 of package}.jpg
 *
 * and a screenshot moved into `Screenshots/<App>/` is filed under that folder.
 */

sealed interface AppHint {
    /** A human readable app name, e.g. "WhatsApp". */
    data class Label(val label: String) : AppHint

    /** An Android package name, e.g. "com.whatsapp". */
    data class Package(val pkg: String) : AppHint

    /** The MD5 of a package name, as used by ColorOS / OxygenOS. */
    data class Hash(val md5: String) : AppHint
}

private val screenshotFolder = Regex("^screen[ _-]?shots?$", RegexOption.IGNORE_CASE)
private val prefix = Regex("^(screen[ _-]?shot|scrnshot|screen[ _-]?capture|capture)s?", RegexOption.IGNORE_CASE)
private val copySuffix = Regex("(\\s*\\(\\d+\\)|~\\d+)$")
private val leadingNoise = Regex("^(?:[ _\\-.]+|\\d+(?=[ _\\-.]|$)|(?:at|from)(?=[ _]))", RegexOption.IGNORE_CASE)
private val trailingNoise = Regex("(?:[ _\\-.]+|(?<=^|[ _\\-.])\\d+|(?<=[ _\\-.])(?:am|pm))$", RegexOption.IGNORE_CASE)
private val letters = Regex("[A-Za-z]")
private val md5 = Regex("^[0-9a-f]{32}$")
private val packageName = Regex("^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+$")
private val spaces = Regex("\\s+")

/**
 * Returns what the file name / folder says about the source app, or null
 * when it gives no clue (e.g. "Screenshot_20240115-093012.png").
 */
fun parseAppHint(fileName: String, folder: String? = null): AppHint? {
    if (!folder.isNullOrEmpty()) {
        val segs = folder.split('/').filter { it.isNotEmpty() }
        val i = segs.indexOfFirst { screenshotFolder.matches(it) }
        if (i >= 0 && i + 1 < segs.size) {
            classify(segs[i + 1])?.let { return it }
        }
    }

    var s = fileName
    val dot = s.lastIndexOf('.')
    if (dot > 0) s = s.substring(0, dot)
    s = copySuffix.replaceFirst(s, "")
    s = prefix.replaceFirst(s, "")
    s = stripRepeatedly(s, leadingNoise, fromStart = true)
    s = stripRepeatedly(s, trailingNoise, fromStart = false)
    return classify(s)
}

private fun stripRepeatedly(input: String, re: Regex, fromStart: Boolean): String {
    var s = input
    while (true) {
        val m = re.find(s) ?: return s
        if (m.range.isEmpty()) return s
        s = if (fromStart) s.substring(m.range.last + 1) else s.substring(0, m.range.first)
    }
}

private fun classify(raw: String): AppHint? {
    val s = raw.trim()
    if (s.isEmpty() || !letters.containsMatchIn(s)) return null
    if (md5.matches(s)) return AppHint.Hash(s)
    if (packageName.matches(s)) return AppHint.Package(s)
    // What's left of a time like "10.30.12 PM".
    if (s.equals("am", true) || s.equals("pm", true)) return null
    // Single letters are allowed: Samsung names X screenshots "..._X.jpg".
    return AppHint.Label(s.replace('_', ' ').replace(spaces, " ").trim())
}

val knownPackages = mapOf(
    "com.whatsapp" to "WhatsApp",
    "com.whatsapp.w4b" to "WhatsApp Business",
    "com.instagram.android" to "Instagram",
    "com.facebook.katana" to "Facebook",
    "com.facebook.lite" to "Facebook Lite",
    "com.facebook.orca" to "Messenger",
    "com.zhiliaoapp.musically" to "TikTok",
    "com.ss.android.ugc.trill" to "TikTok",
    "com.twitter.android" to "X",
    "org.telegram.messenger" to "Telegram",
    "org.thoughtcrime.securesms" to "Signal",
    "com.snapchat.android" to "Snapchat",
    "com.google.android.youtube" to "YouTube",
    "com.android.chrome" to "Chrome",
    "com.google.android.apps.maps" to "Maps",
    "com.google.android.gm" to "Gmail",
    "com.google.android.apps.photos" to "Photos",
    "com.google.android.apps.messaging" to "Messages",
    "com.google.android.googlequicksearchbox" to "Google",
    "com.google.android.calendar" to "Calendar",
    "com.google.android.apps.docs" to "Drive",
    "com.google.android.keep" to "Keep",
    "com.spotify.music" to "Spotify",
    "com.reddit.frontpage" to "Reddit",
    "com.discord" to "Discord",
    "com.linkedin.android" to "LinkedIn",
    "com.pinterest" to "Pinterest",
    "com.netflix.mediaclient" to "Netflix",
    "com.amazon.mshop.android.shopping" to "Amazon",
    "org.mozilla.firefox" to "Firefox",
    "com.microsoft.teams" to "Teams",
    "com.microsoft.office.outlook" to "Outlook",
    "com.slack" to "Slack",
    "com.android.settings" to "Settings",
    "com.samsung.android.messaging" to "Messages",
    "com.sec.android.app.sbrowser" to "Samsung Internet",
    "com.sec.android.gallery3d" to "Gallery",
    "com.miui.gallery" to "Gallery",
    "com.openai.chatgpt" to "ChatGPT",
    "com.anthropic.claude" to "Claude",
    "com.android.systemui" to "System",
    "com.google.android.apps.nexuslauncher" to "Home screen",
    "com.sec.android.app.launcher" to "Home screen",
    "com.miui.home" to "Home screen",
)

private val noiseSegments = setOf(
    "com", "org", "net", "io", "co", "me", "tv", "app", "apps", "android",
    "mobile", "client", "main", "free", "lite", "pro", "www",
)
private val vendorSegments = setOf(
    "google", "samsung", "sec", "microsoft", "miui", "xiaomi", "huawei",
    "oneplus", "oppo", "coloros", "heytap", "motorola", "sony", "lge",
)

/**
 * Best-effort readable name for a package that isn't installed (or that we
 * can't see), e.g. "com.spotify.music" -> "Spotify".
 */
fun prettifyPackage(pkg: String): String {
    knownPackages[pkg.lowercase()]?.let { return it }
    val parts = pkg.split('.').filter { it.isNotEmpty() && it.lowercase() !in noiseSegments }
    if (parts.isEmpty()) return capitalize(pkg.split('.').last())
    val brand = parts.firstOrNull { it.lowercase() !in vendorSegments } ?: parts.last()
    // For vendor apps ("com.google.android.apps.maps") the product is last.
    val pick = if (parts.first().lowercase() in vendorSegments) parts.last() else brand
    return capitalize(pick)
}

private fun capitalize(s: String) = if (s.isEmpty()) s else s[0].uppercaseChar() + s.substring(1)

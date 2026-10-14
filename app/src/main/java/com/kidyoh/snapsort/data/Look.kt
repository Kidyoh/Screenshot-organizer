package com.kidyoh.snapsort.data

import kotlin.math.abs

/*
 * Recognises apps from how a screenshot looks, with fixed rules: no AI.
 *
 * Each screenshot is shrunk to 24 × 52 pixels on the phone ([LookStore]).
 * Two deterministic checks run on that:
 *  * built-in fingerprints for apps with unmistakable colours, and
 *  * matching against the person's own screenshots whose app is already known.
 * The same picture always gets the same answer, and when unsure the answer
 * is "don't know".
 */

const val LOOK_W = 24
const val LOOK_H = 52

/** Header band (below the status bar) and bottom bar, in rows of the tiny image. */
private val headerRows = 2 until 6
private val navRows = 46 until 50

class Look(
    /** ARGB pixels, row by row. */
    val px: IntArray,
) {
    init {
        require(px.size == LOOK_W * LOOK_H)
    }

    /** Share of pixels within [tolerance] of any of [colors] (0xRRGGBB), per channel. */
    fun fraction(colors: IntArray, rows: IntRange = 0 until LOOK_H, tolerance: Int = 18): Double {
        var hit = 0
        var total = 0
        for (y in rows) for (x in 0 until LOOK_W) {
            val p = px[y * LOOK_W + x]
            total++
            for (c in colors) {
                if (abs((p shr 16 and 0xFF) - (c shr 16 and 0xFF)) <= tolerance &&
                    abs((p shr 8 and 0xFF) - (c shr 8 and 0xFF)) <= tolerance &&
                    abs((p and 0xFF) - (c and 0xFF)) <= tolerance
                ) {
                    hit++
                    break
                }
            }
        }
        return if (total == 0) 0.0 else hit.toDouble() / total
    }

    /** Share of all pixels in [rows] × [cols] that pass [test] (on 0-255 RGB). */
    fun share(
        rows: IntRange = 0 until LOOK_H,
        cols: IntRange = 0 until LOOK_W,
        test: (Int, Int, Int) -> Boolean,
    ): Double {
        var hit = 0
        for (y in rows) for (x in cols) {
            val p = px[y * LOOK_W + x]
            if (test(p shr 16 and 0xFF, p shr 8 and 0xFF, p and 0xFF)) hit++
        }
        return hit.toDouble() / (LOOK_W * LOOK_H)
    }

    /**
     * Chat apps put sent messages on the right: plenty of [bubble] in the right
     * half, almost none touching the far left edge.
     */
    fun sentOnRight(min: Double = 0.02, bubble: (Int, Int, Int) -> Boolean): Boolean =
        share(cols = LOOK_W / 2 until LOOK_W, test = bubble) >= min &&
            share(cols = 0 until LOOK_W / 4, test = bubble) <= 0.004

    /**
     * Layout signature: 4 × 4-pixel cell averages, with the header and bottom
     * bar counted three times, since they say the most about which app it is.
     */
    val features: DoubleArray by lazy {
        val out = ArrayList<Double>()
        fun cell(x0: Int, y0: Int, w: Int, h: Int, weight: Int) {
            var r = 0
            var g = 0
            var b = 0
            for (y in y0 until y0 + h) for (x in x0 until x0 + w) {
                val p = px[y * LOOK_W + x]
                r += p shr 16 and 0xFF
                g += p shr 8 and 0xFF
                b += p and 0xFF
            }
            val n = (w * h).toDouble()
            repeat(weight) {
                out += r / n
                out += g / n
                out += b / n
            }
        }
        var y = 0
        while (y + 4 <= LOOK_H) {
            for (x in 0 until LOOK_W step 4) cell(x, y, 4, 4, 1)
            y += 4
        }
        for (band in listOf(headerRows, navRows)) {
            for (x in 0 until LOOK_W step 6) cell(x, band.first, 6, band.last + 1 - band.first, 3)
        }
        out.toDoubleArray()
    }

    /** Mean absolute difference per channel value (0 = identical, 255 = opposite). */
    fun distanceTo(other: Look): Double {
        val a = features
        val b = other.features
        var sum = 0.0
        for (i in a.indices) sum += abs(a[i] - b[i])
        return sum / a.size
    }
}

class Fingerprint(val app: String, val why: String, val test: (Look) -> Boolean)

private fun whatsAppWallpaper(r: Int, g: Int, b: Int) = r >= 215 && r >= g && g >= b && r - b in 6..30
private fun whatsAppSent(r: Int, g: Int, b: Int) = g >= 225 && g - r >= 18 && g - b >= 22
private fun whatsAppDark(r: Int, g: Int, b: Int) = r <= 22 && g in 14..30 && b in 20..36
private fun whatsAppDarkSent(r: Int, g: Int, b: Int) = r <= 18 && g in 78..108 && b in 62..88
private fun telegramDark(r: Int, g: Int, b: Int) = r <= 30 && g in 18..40 && b in 30..52
private fun telegramDarkSent(r: Int, g: Int, b: Int) = r in 30..58 && g in 70..100 && b in 105..135

/**
 * Apps with colours and layouts nothing else shares. Kept strict on
 * purpose: a wrong guess is worse than "Other".
 */
val fingerprints = listOf(
    Fingerprint("WhatsApp", "chat wallpaper with green sent messages on the right") {
        it.share(test = ::whatsAppWallpaper) >= 0.30 && it.sentOnRight(bubble = ::whatsAppSent)
    },
    Fingerprint("WhatsApp", "dark chat with teal sent messages on the right") {
        it.share(test = ::whatsAppDark) >= 0.30 && it.sentOnRight(bubble = ::whatsAppDarkSent)
    },
    Fingerprint("WhatsApp", "green header") {
        it.fraction(intArrayOf(0x075E54, 0x008069), headerRows, 14) >= 0.7
    },
    Fingerprint("Telegram", "blue header") {
        it.fraction(intArrayOf(0x517DA2, 0x527DA3, 0x5682A3), headerRows, 14) >= 0.7
    },
    Fingerprint("Telegram", "dark chat with blue sent messages on the right") {
        it.share(test = ::telegramDark) >= 0.30 && it.sentOnRight(bubble = ::telegramDarkSent)
    },
    Fingerprint("Spotify", "near-black with Spotify green") {
        it.fraction(intArrayOf(0x121212, 0x000000), tolerance = 10) >= 0.45 &&
            it.fraction(intArrayOf(0x1DB954, 0x1ED760), tolerance = 26) >= 0.004
    },
    Fingerprint("Snapchat", "Snapchat yellow") {
        it.fraction(intArrayOf(0xFFFC00), tolerance = 14) >= 0.12
    },
    Fingerprint("Viber", "purple header") {
        it.fraction(intArrayOf(0x7360F2, 0x665CAC), headerRows, 14) >= 0.7
    },
)

fun fingerprintApp(look: Look): String? = fingerprints.firstOrNull { it.test(look) }?.app

/** Compares a screenshot with the person's own screenshots whose app is known. */
class LookMatcher {
    private class Ref(val app: String, val id: Long, val look: Look)

    private val refs = ArrayList<Ref>()

    val size: Int get() = refs.size

    fun add(app: String, id: Long, look: Look) {
        refs += Ref(app, id, look)
    }

    /** The app of the closest references if they agree, else null. */
    fun match(look: Look): String? {
        val near = refs
            .map { Triple(it.app, it.id, look.distanceTo(it.look)) }
            .filter { it.third <= CLOSE }
            // Ties broken by id so the answer never depends on order.
            .sortedWith(compareBy({ it.third }, { it.second }))
        if (near.isEmpty()) return null
        if (near.first().third <= TWIN) return near.first().first
        if (near.size < 2) return null
        val top = near.take(3)
        val app = top.first().first
        return if (top.all { it.first == app }) app else null
    }

    companion object {
        /** Two references closer than this are the same screen type. */
        const val CLOSE = 10.0

        /** Practically the same image (a re-save or near copy). */
        const val TWIN = 3.0
    }
}

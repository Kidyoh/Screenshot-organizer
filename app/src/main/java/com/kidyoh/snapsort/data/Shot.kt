package com.kidyoh.snapsort.data

import java.util.Calendar

/** How SnapSort knows which app a screenshot came from. */
enum class AppSource {
    /** The phone wrote it into the file name or folder. */
    FileName,

    /** Android's usage history: the app that was open at that moment. */
    Usage,

    /** The person picked it. */
    Manual,

    /** Recognised from how the screenshot looks (fixed rules, no AI). */
    Looks,

    /** No clue yet. */
    Unknown,
}

/** One screenshot on the phone. */
data class Shot(
    val id: Long,
    val name: String,
    /** When it was taken, in milliseconds since the epoch. */
    val date: Long,
    val size: Long,
    val width: Int,
    val height: Int,
    /** Folder relative to the storage root, e.g. "Pictures/Screenshots/". */
    val folder: String,
    /** Absolute file path, when Android still reports one. */
    val path: String,
    /** Which app the screenshot was taken in, or [OTHER]. */
    val app: String = OTHER,
    val appSource: AppSource = AppSource.Unknown,
) {
    val aspect: Float get() = if (width > 0 && height > 0) width.toFloat() / height else 9f / 19.5f

    companion object {
        const val OTHER = "Other"
    }
}

/** A titled run of screenshots in a grid. */
data class Section(val title: String, val shots: List<Shot>, val subtitle: String? = null)

private val months = listOf(
    "January", "February", "March", "April", "May", "June", "July",
    "August", "September", "October", "November", "December",
)
private val weekdays = listOf("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")

private fun cal(millis: Long): Calendar = Calendar.getInstance().apply { timeInMillis = millis }

/** Midnight at the start of the day [millis] falls in, minus [daysBack] days. */
fun startOfDay(millis: Long, daysBack: Int = 0): Long = cal(millis).apply {
    set(Calendar.HOUR_OF_DAY, 0)
    set(Calendar.MINUTE, 0)
    set(Calendar.SECOND, 0)
    set(Calendar.MILLISECOND, 0)
    add(Calendar.DAY_OF_MONTH, -daysBack)
}.timeInMillis

fun monthYear(d: Long): String = cal(d).let { "${months[it.get(Calendar.MONTH)]} ${it.get(Calendar.YEAR)}" }

fun shortDate(d: Long, now: Long = System.currentTimeMillis()): String {
    val c = cal(d)
    val base = "${months[c.get(Calendar.MONTH)].take(3)} ${c.get(Calendar.DAY_OF_MONTH)}"
    return if (c.get(Calendar.YEAR) == cal(now).get(Calendar.YEAR)) base else "$base, ${c.get(Calendar.YEAR)}"
}

fun longDate(d: Long): String = cal(d).let {
    "${weekdays[it.get(Calendar.DAY_OF_WEEK) - 1]}, ${months[it.get(Calendar.MONTH)]} " +
        "${it.get(Calendar.DAY_OF_MONTH)}, ${it.get(Calendar.YEAR)}"
}

fun greeting(now: Long = System.currentTimeMillis()): String {
    val h = cal(now).get(Calendar.HOUR_OF_DAY)
    return when {
        h < 5 -> "Up late"
        h < 12 -> "Good morning"
        h < 18 -> "Good afternoon"
        else -> "Good evening"
    }
}

fun timeOfDay(d: Long): String {
    val c = cal(d)
    val hour = c.get(Calendar.HOUR_OF_DAY)
    val h = if (hour % 12 == 0) 12 else hour % 12
    return "$h:${c.get(Calendar.MINUTE).toString().padStart(2, '0')} ${if (hour < 12) "AM" else "PM"}"
}

/** Groups newest-first shots into Today / Yesterday / This week / months. */
fun sectionsByDate(shots: List<Shot>, now: Long = System.currentTimeMillis()): List<Section> {
    val today = startOfDay(now)
    val yesterday = startOfDay(now, 1)
    val weekAgo = startOfDay(now, 6)
    val out = ArrayList<Section>()
    var current: String? = null
    var bucket: ArrayList<Shot>? = null
    for (s in shots) {
        val title = when {
            s.date >= today -> "Today"
            s.date >= yesterday -> "Yesterday"
            s.date >= weekAgo -> "This week"
            else -> monthYear(s.date)
        }
        if (title != current) {
            current = title
            bucket = ArrayList()
            out += Section(title, bucket)
        }
        bucket!!.add(s)
    }
    return out
}

/** Groups shots by month, keeping their order. */
fun sectionsByMonth(shots: List<Shot>): List<Section> {
    val out = ArrayList<Section>()
    var bucket: ArrayList<Shot>? = null
    for (s in shots) {
        val title = monthYear(s.date)
        if (out.isEmpty() || out.last().title != title) {
            bucket = ArrayList()
            out += Section(title, bucket)
        }
        bucket!!.add(s)
    }
    return out
}

fun formatBytes(bytes: Long): String {
    if (bytes < 1024) return "$bytes B"
    val units = listOf("KB", "MB", "GB", "TB")
    var v = bytes / 1024.0
    var i = 0
    while (v >= 1024 && i < units.size - 1) {
        v /= 1024
        i++
    }
    return "${fixed(v, if (v >= 100 || i == 0) 0 else 1)} ${units[i]}"
}

fun formatCount(n: Int, noun: String): String {
    val s = n.toString().reversed().chunked(3).joinToString(",").reversed()
    return "$s $noun${if (n == 1) "" else "s"}"
}

/** Like Dart's toStringAsFixed: rounds half up, no locale surprises. */
fun fixed(v: Double, digits: Int): String {
    if (digits == 0) return Math.round(v).toString()
    val f = Math.pow(10.0, digits.toDouble())
    val r = Math.round(v * f)
    val whole = r / f.toLong()
    val frac = (r % f.toLong()).toString().padStart(digits, '0')
    return "$whole.$frac"
}

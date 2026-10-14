package com.kidyoh.snapsort.data

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process

/**
 * Works out which app was on screen when a screenshot was taken, from Android's
 * own usage history (needs the "Usage access" permission, which the person
 * turns on in Settings). Android only keeps that history for about a week, so
 * every answer is saved, and [com.kidyoh.snapsort.LabelJob] keeps labelling new screenshots.
 */
class UsageResolver(private val context: Context) {
    private val prefs = context.getSharedPreferences("snapsort_usage", Context.MODE_PRIVATE)

    fun hasAccess(): Boolean {
        val ops = context.getSystemService(AppOpsManager::class.java) ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Screenshot id -> package name, for the shots we know or can work out. */
    fun resolve(shots: List<Pair<Long, Long>>): Map<Long, String> {
        val out = HashMap<Long, String>()
        val missing = ArrayList<Pair<Long, Long>>()
        for ((id, time) in shots) {
            val known = prefs.getString(id.toString(), null)
            if (known != null) out[id] = known else missing += id to time
        }
        if (missing.isEmpty() || !hasAccess()) return out

        val usm = context.getSystemService(UsageStatsManager::class.java) ?: return out
        val start = missing.minOf { it.second } - 6 * 3600_000L
        val end = missing.maxOf { it.second } + 5_000L
        val times = ArrayList<Long>()
        val packages = ArrayList<String>()
        val events = usm.queryEvents(start, end)
        val e = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            // 1 = MOVE_TO_FOREGROUND / ACTIVITY_RESUMED
            val pkg: String? = e.packageName
            if (e.eventType == 1 && pkg != null && pkg !in IGNORED) {
                times += e.timeStamp
                packages += pkg
            }
        }
        if (times.isEmpty()) return out

        val editor = prefs.edit()
        for ((id, time) in missing) {
            // Last app that came to the front at or just before the screenshot.
            var lo = 0
            var hi = times.size - 1
            var found = -1
            while (lo <= hi) {
                val mid = (lo + hi) ushr 1
                if (times[mid] <= time + 500) { found = mid; lo = mid + 1 } else hi = mid - 1
            }
            // Before the oldest event Android kept, we can't tell.
            if (found < 0) continue
            out[id] = packages[found]
            editor.putString(id.toString(), packages[found])
        }
        editor.apply()
        return out
    }

    companion object {
        // Screens that flash up around a screenshot but aren't what was captured.
        private val IGNORED = setOf(
            "android",
            "com.android.systemui",
            "com.samsung.android.app.smartcapture",
            "com.miui.screenshot",
            "com.oplus.screenshot",
            "com.coloros.screenshot",
            "com.huawei.screenshot",
            "com.transsion.screenshot",
        )
    }
}

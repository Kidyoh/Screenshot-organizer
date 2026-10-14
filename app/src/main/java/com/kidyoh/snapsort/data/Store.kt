package com.kidyoh.snapsort.data

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.ObjectInputStream

/** Saved state: favourites, albums, choices. Kept in one small preferences file. */
class Store(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("snapsort", Context.MODE_PRIVATE)

    init {
        if (!prefs.getBoolean(MIGRATED, false)) {
            migrateFromFlutter(context)
            prefs.edit().putBoolean(MIGRATED, true).apply()
        }
    }

    var themeMode: Int
        get() = prefs.getInt("themeMode", 0)
        set(v) = prefs.edit().putInt("themeMode", v).apply()

    var favorites: Set<Long>
        get() = ids("favorites")
        set(v) = putIds("favorites", v)

    var reviewed: Set<Long>
        get() = ids("reviewed")
        set(v) = putIds("reviewed", v)

    var albums: Map<String, List<Long>>
        get() = try {
            val o = JSONObject(prefs.getString("albums", null) ?: "{}")
            val out = LinkedHashMap<String, List<Long>>()
            for (k in o.keys()) {
                val a = o.getJSONArray(k)
                out[k] = List(a.length()) { a.getLong(it) }
            }
            out
        } catch (_: Exception) {
            emptyMap()
        }
        set(v) {
            val o = JSONObject()
            for ((k, list) in v) o.put(k, JSONArray(list))
            prefs.edit().putString("albums", o.toString()).apply()
        }

    var appOverrides: Map<Long, String>
        get() = try {
            val o = JSONObject(prefs.getString("appOverrides", null) ?: "{}")
            o.keys().asSequence().associate { it.toLong() to o.getString(it) }
        } catch (_: Exception) {
            emptyMap()
        }
        set(v) {
            val o = JSONObject()
            for ((k, app) in v) o.put(k.toString(), app)
            prefs.edit().putString("appOverrides", o.toString()).apply()
        }

    var usageCardDismissed: Boolean
        get() = prefs.getBoolean("usageCardDismissed", false)
        set(v) = prefs.edit().putBoolean("usageCardDismissed", v).apply()

    var usagePromptShown: Boolean
        get() = prefs.getBoolean("usagePromptShown", false)
        set(v) = prefs.edit().putBoolean("usagePromptShown", v).apply()

    /** The person has been asked for photo access at least once. */
    var askedForPhotos: Boolean
        get() = prefs.getBoolean("askedForPhotos", false)
        set(v) = prefs.edit().putBoolean("askedForPhotos", v).apply()

    /** WorkManager jobs from the Flutter builds have been cancelled. */
    var clearedOldJobs: Boolean
        get() = prefs.getBoolean("clearedOldJobs", false)
        set(v) = prefs.edit().putBoolean("clearedOldJobs", v).apply()

    private fun ids(key: String): Set<Long> =
        prefs.getString(key, null)?.split(',')?.mapNotNull { it.toLongOrNull() }?.toSet() ?: emptySet()

    private fun putIds(key: String, v: Set<Long>) = prefs.edit().putString(key, v.joinToString(",")).apply()

    /**
     * Versions up to 1.3 were built with Flutter, which kept the same things in
     * "FlutterSharedPreferences" with a "flutter." prefix. Carry them over so
     * updating keeps albums and favourites.
     */
    private fun migrateFromFlutter(context: Context) {
        val old = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (old.all.isEmpty()) return
        val e = prefs.edit()
        fun list(key: String): List<String>? {
            val raw = old.getString("flutter.$key", null) ?: return null
            if (!raw.startsWith(LIST_PREFIX)) return null
            val body = raw.removePrefix(LIST_PREFIX)
            return try {
                if (body.startsWith("!")) {
                    val a = JSONArray(body.substring(1))
                    List(a.length()) { a.getString(it) }
                } else {
                    @Suppress("UNCHECKED_CAST")
                    ObjectInputStream(Base64.decode(body, 0).inputStream()).use { it.readObject() as List<String> }
                }
            } catch (_: Exception) {
                null
            }
        }
        list("favorites")?.let { e.putString("favorites", it.joinToString(",")) }
        list("reviewed")?.let { e.putString("reviewed", it.joinToString(",")) }
        old.getString("flutter.albums", null)?.let { e.putString("albums", it) }
        old.getString("flutter.appOverrides", null)?.let { e.putString("appOverrides", it) }
        for (key in listOf("usageCardDismissed", "usagePromptShown")) {
            if (old.contains("flutter.$key")) e.putBoolean(key, old.getBoolean("flutter.$key", false))
        }
        (old.all["flutter.themeMode"] as? Number)?.let { e.putInt("themeMode", it.toInt()) }
        e.apply()
    }

    companion object {
        private const val MIGRATED = "migratedFromFlutter"
        private const val LIST_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu"
    }
}

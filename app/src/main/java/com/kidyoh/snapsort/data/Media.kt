package com.kidyoh.snapsort.data

import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import com.kidyoh.snapsort.LabelJob
import java.security.MessageDigest

/** What MediaStore and the package manager can tell us. All calls block: run them off the main thread. */
open class Media(private val context: Context) {
    open fun query(): List<Shot> = ScreenshotStore.query(context)

    /** Package name -> app label, for installed apps. */
    open fun appLabels(packages: Collection<String>): Map<String, String> {
        val pm = context.packageManager
        val out = HashMap<String, String>()
        for (p in packages) {
            try {
                out[p] = pm.getApplicationLabel(pm.getApplicationInfo(p, 0)).toString()
            } catch (_: PackageManager.NameNotFoundException) {
            }
        }
        return out
    }

    /** md5(packageName) -> app label, for phones that name screenshots by package hash. */
    open fun hashLabels(): Map<String, String> {
        val pm = context.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val out = HashMap<String, String>()
        @Suppress("DEPRECATION")
        for (info in pm.queryIntentActivities(launcher, 0)) {
            val pkg = info.activityInfo.packageName
            out[hex(MessageDigest.getInstance("MD5").digest(pkg.toByteArray()))] = info.loadLabel(pm).toString()
        }
        return out
    }

    /** Screenshot id -> md5 of the file. */
    open fun md5(ids: List<Long>): Map<Long, String> {
        val out = HashMap<Long, String>()
        val buf = ByteArray(64 * 1024)
        for (id in ids) {
            try {
                val digest = MessageDigest.getInstance("MD5")
                context.contentResolver.openInputStream(uri(id))?.use { input ->
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        digest.update(buf, 0, n)
                    }
                } ?: continue
                out[id] = hex(digest.digest())
            } catch (_: Exception) {
            }
        }
        return out
    }

    /** Whether the person turned on Usage access for SnapSort. */
    open fun usageAccess(): Boolean = UsageResolver(context).hasAccess()

    /**
     * Screenshot id -> package of the app that was open when it was taken,
     * for the ones Android's usage history (or earlier lookups) can answer.
     */
    open fun appsAt(times: Map<Long, Long>): Map<Long, String> {
        if (times.isEmpty()) return emptyMap()
        val resolver = UsageResolver(context)
        if (resolver.hasAccess()) LabelJob.schedule(context)
        return resolver.resolve(times.map { (k, v) -> k to v })
    }

    /** 24 × 52 ARGB copies of screenshots, for recognising apps by look. */
    open fun looks(ids: List<Long>): Map<Long, IntArray> = LookStore(context).looks(ids)

    /** Details of the last crash, if the app closed unexpectedly (read once). */
    open fun lastCrash(): String? = CrashLog.take(context)

    companion object {
        fun uri(id: Long): Uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)

        private fun hex(bytes: ByteArray) = bytes.joinToString("") { "%02x".format(it) }
    }
}

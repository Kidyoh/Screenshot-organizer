package com.kidyoh.snapsort

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingTrash: MethodChannel.Result? = null
    private var pendingDelete: Pair<List<Long>, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "snapsort/media")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "query" -> background(result) { ScreenshotStore.query(this) }
                    "appLabels" -> background(result) {
                        appLabels(call.argument<List<String>>("packages").orEmpty())
                    }
                    "hashLabels" -> background(result) { hashLabels() }
                    "usageAccess" -> result.success(UsageResolver(this).hasAccess())
                    "openUsageAccess" -> {
                        openUsageAccess()
                        result.success(null)
                    }
                    "appsAt" -> background(result) {
                        val raw = call.argument<Map<String, Number>>("times").orEmpty()
                        val resolver = UsageResolver(this)
                        if (resolver.hasAccess()) LabelWorker.schedule(this)
                        resolver.resolve(raw.map { (k, v) -> k.toLong() to v.toLong() })
                    }
                    "md5" -> background(result) { md5(ids(call.argument("ids"))) }
                    "trash" -> trash(ids(call.argument("ids")), result)
                    "share" -> {
                        share(ids(call.argument("ids")))
                        result.success(null)
                    }
                    "openWith" -> {
                        openWith(ids(call.argument("ids")).first())
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Exception) {
                mainHandler.post { result.error("media", e.message, null) }
            }
        }
    }

    private fun ids(raw: Any?): List<Long> =
        (raw as? List<*>).orEmpty().map { (it as Number).toLong() }

    private fun uri(id: Long): Uri =
        ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)

    private fun appLabels(packages: List<String>): Map<String, String> {
        val pm = packageManager
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
    private fun hashLabels(): Map<String, String> {
        val pm = packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val out = HashMap<String, String>()
        @Suppress("DEPRECATION")
        for (info in pm.queryIntentActivities(launcher, 0)) {
            val pkg = info.activityInfo.packageName
            out[hex(MessageDigest.getInstance("MD5").digest(pkg.toByteArray()))] =
                info.loadLabel(pm).toString()
        }
        return out
    }

    private fun md5(ids: List<Long>): Map<String, String> {
        val out = HashMap<String, String>()
        val buf = ByteArray(64 * 1024)
        for (id in ids) {
            try {
                val digest = MessageDigest.getInstance("MD5")
                contentResolver.openInputStream(uri(id))?.use { input ->
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        digest.update(buf, 0, n)
                    }
                } ?: continue
                out[id.toString()] = hex(digest.digest())
            } catch (_: Exception) {
            }
        }
        return out
    }

    private fun openUsageAccess() {
        val direct = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, Uri.parse("package:$packageName"))
        try {
            startActivity(direct)
        } catch (_: Exception) {
            // Some phones only open the general list.
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    private fun hex(bytes: ByteArray) = bytes.joinToString("") { "%02x".format(it) }

    private fun trash(ids: List<Long>, result: MethodChannel.Result) {
        if (ids.isEmpty()) return result.success(true)
        val uris = ids.map(::uri)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+: system dialog, files go to the recycle bin for 30 days.
            if (pendingTrash != null) return result.error("busy", "Another delete is in progress", null)
            try {
                val request = MediaStore.createTrashRequest(contentResolver, uris, true)
                pendingTrash = result
                startIntentSenderForResult(request.intentSender, TRASH_REQUEST, null, 0, 0, 0)
            } catch (e: Exception) {
                pendingTrash = null
                result.error("trash", e.message, null)
            }
        } else {
            // Android 10 and older delete directly, which needs the storage
            // write permission (Android 10 is never asked for it up front).
            if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                if (pendingDelete != null) return result.error("busy", "Another delete is in progress", null)
                pendingDelete = ids to result
                requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), WRITE_REQUEST)
                return
            }
            deleteDirectly(uris, result)
        }
    }

    private fun deleteDirectly(uris: List<Uri>, result: MethodChannel.Result) {
        background(result) {
            var ok = true
            for (u in uris) {
                try {
                    if (contentResolver.delete(u, null, null) == 0) ok = false
                } catch (_: SecurityException) {
                    ok = false
                }
            }
            ok
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != WRITE_REQUEST) return
        val (ids, result) = pendingDelete ?: return
        pendingDelete = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            deleteDirectly(ids.map(::uri), result)
        } else {
            result.success(false)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == TRASH_REQUEST) {
            pendingTrash?.success(resultCode == Activity.RESULT_OK)
            pendingTrash = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun share(ids: List<Long>) {
        if (ids.isEmpty()) return
        val uris = ArrayList(ids.map(::uri))
        val intent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris[0])
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        }
        intent.type = "image/*"
        intent.clipData = ClipData.newRawUri(null, uris[0]).apply {
            uris.drop(1).forEach { addItem(ClipData.Item(it)) }
        }
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(Intent.createChooser(intent, null))
    }

    private fun openWith(id: Long) {
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri(id), "image/*")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(Intent.createChooser(intent, null))
    }

    companion object {
        private const val TRASH_REQUEST = 4242
        private const val WRITE_REQUEST = 4243
    }
}

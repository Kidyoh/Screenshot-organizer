package com.kidyoh.snapsort

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "snapsort/media")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "query" -> background(result) { queryScreenshots() }
                    "appLabels" -> background(result) {
                        appLabels(call.argument<List<String>>("packages").orEmpty())
                    }
                    "hashLabels" -> background(result) { hashLabels() }
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

    /** Every image living in a "Screenshots" folder (or a subfolder of one). */
    private fun queryScreenshots(): List<Map<String, Any?>> {
        val hasRelativePath = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        val projection = mutableListOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATE_TAKEN,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.SIZE,
            MediaStore.Images.Media.WIDTH,
            MediaStore.Images.Media.HEIGHT,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
            @Suppress("DEPRECATION") MediaStore.Images.Media.DATA,
        )
        if (hasRelativePath) projection += MediaStore.Images.Media.RELATIVE_PATH
        val pathColumn = if (hasRelativePath) MediaStore.Images.Media.RELATIVE_PATH
        else @Suppress("DEPRECATION") MediaStore.Images.Media.DATA
        val selection =
            "($pathColumn LIKE ? OR ${MediaStore.Images.Media.BUCKET_DISPLAY_NAME} LIKE ?)"
        val args = arrayOf("%screenshot%", "%screenshot%")

        val out = ArrayList<Map<String, Any?>>()
        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection.toTypedArray(),
            selection, args, "${MediaStore.Images.Media.DATE_ADDED} DESC"
        )?.use { c ->
            val idCol = c.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val nameCol = c.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
            val takenCol = c.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_TAKEN)
            val addedCol = c.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
            val sizeCol = c.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
            val wCol = c.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH)
            val hCol = c.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT)
            @Suppress("DEPRECATION")
            val dataCol = c.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            val relCol = if (hasRelativePath) c.getColumnIndex(MediaStore.Images.Media.RELATIVE_PATH) else -1
            while (c.moveToNext()) {
                val data = c.getString(dataCol) ?: ""
                var taken = c.getLong(takenCol)
                if (taken <= 0) taken = c.getLong(addedCol) * 1000
                var folder = if (relCol >= 0) c.getString(relCol) ?: "" else ""
                if (folder.isEmpty() && data.isNotEmpty()) {
                    // Turn /storage/emulated/0/Pictures/Screenshots/x.png into Pictures/Screenshots/
                    folder = (File(data).parent ?: "").substringAfter("/emulated/0/", "") + "/"
                }
                out += mapOf(
                    "id" to c.getLong(idCol),
                    "name" to (c.getString(nameCol) ?: File(data).name),
                    "date" to taken,
                    "size" to c.getLong(sizeCol),
                    "width" to c.getInt(wCol),
                    "height" to c.getInt(hCol),
                    "folder" to folder,
                    "path" to data,
                )
            }
        }
        return out
    }

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
    }
}

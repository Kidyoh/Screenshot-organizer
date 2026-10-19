package com.kidyoh.snapsort

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.kidyoh.snapsort.data.CrashLog
import com.kidyoh.snapsort.data.Host
import com.kidyoh.snapsort.data.Library
import com.kidyoh.snapsort.data.Media
import com.kidyoh.snapsort.data.PhotoAccess
import com.kidyoh.snapsort.data.Store
import com.kidyoh.snapsort.data.Thumbs
import com.kidyoh.snapsort.ui.SnapSortApp
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Holds the library for the whole process, so it outlives the activity. */
class SnapSort : Application() {
    val store by lazy { Store(this) }
    val library by lazy { Library(Media(this), store) }
    val thumbs by lazy { Thumbs(this) }

    override fun onCreate() {
        CrashLog.install(this)
        super.onCreate()
        if (!store.clearedOldJobs) {
            LabelJob.clearOldJobs(this)
            store.clearedOldJobs = true
        }
    }
}

class MainActivity : ComponentActivity(), Host {
    private val app get() = application as SnapSort

    private var pendingPhotos: CompletableDeferred<Unit>? = null
    private val photosRequest = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        pendingPhotos?.complete(Unit)
        pendingPhotos = null
    }

    private var pendingTrash: CompletableDeferred<Boolean>? = null
    private val trashRequest = registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) {
        pendingTrash?.complete(it.resultCode == Activity.RESULT_OK)
        pendingTrash = null
    }

    private var pendingWrite: CompletableDeferred<Boolean>? = null
    private val writeRequest = registerForActivityResult(ActivityResultContracts.RequestPermission()) {
        pendingWrite?.complete(it)
        pendingWrite = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        app.library.host = this
        setBars(dark = false)
        setContent { SnapSortApp(app.library, app.thumbs) }
    }

    override fun onResume() {
        super.onResume()
        // Pick up new screenshots, and permission changes made in Settings.
        app.library.host = this
        app.library.checkAccess()
    }

    /** Light icons on dark screens and the other way round. */
    fun setBars(dark: Boolean) {
        val style = if (dark) SystemBarStyle.dark(Color.TRANSPARENT)
        else SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT)
        enableEdgeToEdge(style, style)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) window.isNavigationBarContrastEnforced = false
    }

    private fun granted(permission: String) = checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    override fun photoAccess(): PhotoAccess = when {
        Build.VERSION.SDK_INT >= 33 && granted(Manifest.permission.READ_MEDIA_IMAGES) -> PhotoAccess.All
        Build.VERSION.SDK_INT < 33 && granted(Manifest.permission.READ_EXTERNAL_STORAGE) -> PhotoAccess.All
        Build.VERSION.SDK_INT >= 34 && granted(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED) -> PhotoAccess.Limited
        else -> PhotoAccess.Denied
    }

    override suspend fun requestPhotos() {
        val permissions = when {
            Build.VERSION.SDK_INT >= 34 -> arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED,
            )
            Build.VERSION.SDK_INT >= 33 -> arrayOf(Manifest.permission.READ_MEDIA_IMAGES)
            else -> arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        val done = CompletableDeferred<Unit>().also { pendingPhotos = it }
        try {
            photosRequest.launch(permissions)
            done.await()
        } catch (_: Exception) {
            pendingPhotos = null
        }
    }

    override suspend fun trash(ids: List<Long>): Boolean {
        if (ids.isEmpty()) return true
        val uris = ids.map(Media::uri)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+: system dialog, files go to the recycle bin for 30 days.
            if (pendingTrash != null) return false
            val done = CompletableDeferred<Boolean>().also { pendingTrash = it }
            return try {
                val request = MediaStore.createTrashRequest(contentResolver, uris, true)
                trashRequest.launch(IntentSenderRequest.Builder(request.intentSender).build())
                done.await()
            } catch (_: Exception) {
                pendingTrash = null
                false
            }
        }
        // Android 10 and older delete directly, which needs the storage write
        // permission (Android 10 is never asked for it up front).
        @Suppress("DEPRECATION")
        val write = Manifest.permission.WRITE_EXTERNAL_STORAGE
        if (!granted(write)) {
            if (pendingWrite != null) return false
            val done = CompletableDeferred<Boolean>().also { pendingWrite = it }
            writeRequest.launch(write)
            if (!done.await()) return false
        }
        return withContext(Dispatchers.IO) {
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

    /** Starts another app without letting a failure crash this one. */
    private fun launch(intent: Intent) {
        try {
            startActivity(intent)
        } catch (_: Exception) {
        }
    }

    override fun share(ids: List<Long>) {
        if (ids.isEmpty()) return
        val uris = ArrayList(ids.map(Media::uri))
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
        launch(Intent.createChooser(intent, null))
    }

    override fun openWith(id: Long) {
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(Media.uri(id), "image/*")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        launch(Intent.createChooser(intent, null))
    }

    override fun shareText(text: String) {
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        launch(Intent.createChooser(send, null))
    }

    override fun openUsageAccess() {
        try {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, Uri.parse("package:$packageName")))
        } catch (_: Exception) {
            // Some phones only open the general list.
            launch(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    override fun openAppSettings() {
        launch(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
    }

    override fun openLink(url: String) {
        launch(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }
}

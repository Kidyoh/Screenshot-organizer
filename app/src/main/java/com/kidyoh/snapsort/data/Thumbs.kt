package com.kidyoh.snapsort.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.LruCache
import android.util.Size
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.withContext

/** Decodes screenshots at the size they're shown, with a memory cache. */
class Thumbs(private val context: Context) {
    private val cache = object : LruCache<String, ImageBitmap>(
        (Runtime.getRuntime().maxMemory() / 6).coerceAtMost(96L * 1024 * 1024).toInt(),
    ) {
        override fun sizeOf(key: String, value: ImageBitmap) = value.width * value.height * 4
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    private val io = Dispatchers.IO.limitedParallelism(3)

    fun cached(id: Long, width: Int): ImageBitmap? = cache.get("$id:$width")

    /** A copy about [width] pixels wide (never upscaled), or null if it can't be read. */
    suspend fun load(id: Long, width: Int): ImageBitmap? {
        val key = "$id:$width"
        cache.get(key)?.let { return it }
        return withContext(io) {
            cache.get(key) ?: decode(id, width)?.asImageBitmap()?.also { cache.put(key, it) }
        }
    }

    private fun decode(id: Long, width: Int): Bitmap? = try {
        val uri = Media.uri(id)
        val resolver = context.contentResolver
        if (width <= THUMB && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // MediaStore keeps small copies already; much faster than the file.
            resolver.loadThumbnail(uri, Size(width, width * 3), null)
        } else {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= width) sample *= 2
            val opts = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = if (width <= THUMB) Bitmap.Config.RGB_565 else Bitmap.Config.ARGB_8888
            }
            resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, opts) }
        }
    } catch (_: Throwable) {
        null
    }

    companion object {
        /** Width of grid thumbnails. */
        const val THUMB = 270

        /** Width of big cards. */
        const val LARGE = 1080

        /** Width in the full-screen viewer, enough for zooming in. */
        const val FULL = 2160
    }
}

package com.kidyoh.snapsort

import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.provider.MediaStore
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File

/**
 * A tiny, fixed-size copy of each screenshot (24 × 52 pixels) that the Dart
 * side compares with fixed rules to recognise apps by how they look. Made once
 * per screenshot and kept in a file, because decoding full screenshots is slow
 * on budget phones.
 */
class LookStore(private val context: Context) {
    private val file = File(context.filesDir, "looks.bin")

    @Synchronized
    fun looks(ids: List<Long>): Map<String, IntArray> {
        val cache = load()
        val out = HashMap<String, IntArray>()
        var changed = false
        for (id in ids) {
            val px = cache[id] ?: make(id)?.also { cache[id] = it; changed = true } ?: continue
            out[id.toString()] = px
        }
        if (changed) save(cache)
        return out
    }

    private fun make(id: Long): IntArray? = try {
        val uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        context.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= W * 2) sample *= 2
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val bmp = context.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, opts) }
        bmp?.let {
            val small = Bitmap.createScaledBitmap(it, W, H, true)
            val px = IntArray(W * H)
            small.getPixels(px, 0, W, 0, 0, W, H)
            if (small !== it) small.recycle()
            it.recycle()
            px
        }
    } catch (_: Exception) {
        null
    }

    @Synchronized
    private fun load(): HashMap<Long, IntArray> {
        memo?.let { return it }
        val map = HashMap<Long, IntArray>()
        if (file.exists()) {
            try {
                DataInputStream(file.inputStream().buffered()).use { input ->
                    if (input.readInt() == VERSION) {
                        repeat(input.readInt()) {
                            val id = input.readLong()
                            map[id] = IntArray(W * H) { input.readInt() }
                        }
                    }
                }
            } catch (_: Exception) {
                map.clear()
            }
        }
        memo = map
        return map
    }

    @Synchronized
    private fun save(map: HashMap<Long, IntArray>) {
        val tmp = File(file.path + ".tmp")
        DataOutputStream(tmp.outputStream().buffered()).use { out ->
            out.writeInt(VERSION)
            out.writeInt(map.size)
            for ((id, px) in map) {
                out.writeLong(id)
                px.forEach(out::writeInt)
            }
        }
        tmp.renameTo(file)
    }

    companion object {
        const val W = 24
        const val H = 52
        private const val VERSION = 1
        @Volatile private var memo: HashMap<Long, IntArray>? = null
    }
}

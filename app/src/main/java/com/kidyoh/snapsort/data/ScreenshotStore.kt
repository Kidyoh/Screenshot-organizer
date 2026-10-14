package com.kidyoh.snapsort.data

import android.content.Context
import android.os.Build
import android.provider.MediaStore
import java.io.File

/** Reads screenshots from MediaStore; shared by the app and [com.kidyoh.snapsort.LabelJob]. */
object ScreenshotStore {
    /** Every image living in a "Screenshots" folder (or a subfolder of one). */
    fun query(context: Context): List<Shot> {
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

        val out = ArrayList<Shot>()
        context.contentResolver.query(
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
                out += Shot(
                    id = c.getLong(idCol),
                    name = c.getString(nameCol) ?: File(data).name,
                    date = taken,
                    size = c.getLong(sizeCol),
                    width = c.getInt(wCol),
                    height = c.getInt(hCol),
                    folder = folder,
                    path = data,
                )
            }
        }
        return out
    }

}

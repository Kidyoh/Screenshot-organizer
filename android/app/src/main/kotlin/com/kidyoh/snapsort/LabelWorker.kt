package com.kidyoh.snapsort

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Twice a day, labels new screenshots with the app that was open, before
 * Android's usage history for that moment expires. Does nothing without
 * Usage access.
 */
class LabelWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val resolver = UsageResolver(applicationContext)
        if (!resolver.hasAccess()) return Result.success()
        return try {
            val shots = ScreenshotStore.query(applicationContext).map {
                (it["id"] as Long) to (it["date"] as Long)
            }
            resolver.resolve(shots)
            Result.success()
        } catch (_: Throwable) {
            Result.retry()
        }
    }

    companion object {
        fun schedule(context: Context) {
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                "label-screenshots",
                ExistingPeriodicWorkPolicy.KEEP,
                PeriodicWorkRequestBuilder<LabelWorker>(12, TimeUnit.HOURS).build(),
            )
        }
    }
}

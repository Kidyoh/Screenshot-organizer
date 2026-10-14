package com.kidyoh.snapsort

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import com.kidyoh.snapsort.data.ScreenshotStore
import com.kidyoh.snapsort.data.UsageResolver
import kotlin.concurrent.thread

/**
 * Twice a day, labels new screenshots with the app that was open, before
 * Android's usage history for that moment expires. Does nothing without
 * Usage access. Uses the platform job scheduler, so no extra libraries.
 */
class LabelJob : JobService() {
    override fun onStartJob(params: JobParameters): Boolean {
        thread(name = "label-screenshots") {
            try {
                val resolver = UsageResolver(applicationContext)
                if (resolver.hasAccess()) {
                    resolver.resolve(ScreenshotStore.query(applicationContext).map { it.id to it.date })
                }
            } catch (_: Throwable) {
            }
            jobFinished(params, false)
        }
        return true
    }

    override fun onStopJob(params: JobParameters) = true

    companion object {
        private const val ID = 1207

        fun schedule(context: Context) {
            val scheduler = context.getSystemService(JobScheduler::class.java) ?: return
            if (scheduler.getPendingJob(ID) != null) return
            scheduler.schedule(
                JobInfo.Builder(ID, ComponentName(context, LabelJob::class.java))
                    .setPeriodic(12 * 3600_000L)
                    .setPersisted(true)
                    .build(),
            )
        }

        /** Jobs left behind by the Flutter builds, which used WorkManager. */
        fun clearOldJobs(context: Context) {
            val scheduler = context.getSystemService(JobScheduler::class.java) ?: return
            scheduler.allPendingJobs.filter { it.id != ID }.forEach { scheduler.cancel(it.id) }
        }
    }
}

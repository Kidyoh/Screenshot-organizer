package com.kidyoh.snapsort.data

import org.junit.Assert.assertEquals
import org.junit.Test

class ShotTest {
    @Test fun formatsBytesLikeBefore() {
        assertEquals("512 B", formatBytes(512))
        assertEquals("711 KB", formatBytes(728_000))
        assertEquals("1.5 MB", formatBytes(1_572_864))
        assertEquals("120 MB", formatBytes(125_829_120))
    }

    @Test fun countsWithSeparators() {
        assertEquals("1 screenshot", formatCount(1, "screenshot"))
        assertEquals("1,234 screenshots", formatCount(1234, "screenshot"))
    }

    @Test fun groupsByDay() {
        val now = startOfDay(System.currentTimeMillis()) + 12 * 3600_000L
        fun shot(id: Long, hoursAgo: Long) = Shot(id, "s$id.png", now - hoursAgo * 3600_000L, 1, 1, 1, "", "")
        val sections = sectionsByDate(listOf(shot(1, 1), shot(2, 20), shot(3, 60), shot(4, 24 * 40)), now)
        assertEquals(listOf("Today", "Yesterday", "This week"), sections.take(3).map { it.title })
        assertEquals(4, sections.size)
    }

    @Test fun groupsOtherLast() {
        fun shot(id: Long, app: String) = Shot(id, "", 0, 1, 1, 1, "", "", app)
        val groups = Library.groupByApp(listOf(shot(1, "Other"), shot(2, "Other"), shot(3, "Chrome"), shot(4, "maps"), shot(5, "Maps")))
        assertEquals(listOf("Chrome", "maps", "Maps", "Other"), groups.map { it.name })
    }
}

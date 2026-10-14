package com.kidyoh.snapsort.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CopyAll
import androidx.compose.material.icons.rounded.History
import androidx.compose.material.icons.rounded.PhotoSizeSelectLarge
import androidx.compose.material.icons.rounded.Swipe
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kidyoh.snapsort.data.Library
import com.kidyoh.snapsort.data.Section
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.fixed
import com.kidyoh.snapsort.data.formatBytes
import com.kidyoh.snapsort.data.formatCount
import com.kidyoh.snapsort.data.sectionsByDate
import com.kidyoh.snapsort.data.shortDate
import com.kidyoh.snapsort.ui.AppState
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.CountUp
import com.kidyoh.snapsort.ui.Dot
import com.kidyoh.snapsort.ui.GroupRoute
import com.kidyoh.snapsort.ui.IconBadge
import com.kidyoh.snapsort.ui.Insets
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.Panel
import com.kidyoh.snapsort.ui.PillButton
import com.kidyoh.snapsort.ui.PillStyle
import com.kidyoh.snapsort.ui.PillTabs
import com.kidyoh.snapsort.ui.ProgressBar
import com.kidyoh.snapsort.ui.SegmentBar
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.colorFor
import com.kidyoh.snapsort.ui.entrance
import com.kidyoh.snapsort.ui.serif
import com.kidyoh.snapsort.ui.tokens

private val ages = linkedMapOf(30 to "30 days", 90 to "3 months", 365 to "1 year")
private const val BIGGEST = 40

private fun AppState.review(
    title: String,
    sections: (Library) -> List<Section>,
    preselect: Set<Long> = emptySet(),
    hint: String? = null,
    empty: String = "Nothing left to clean up here.",
) = push(GroupRoute(title, "Review", sections, initialSelection = preselect, hint = hint, emptyMessage = empty))

/** Storage overview plus tools for duplicates, old and big screenshots. */
@Composable
fun CleanupScreen() {
    val app = LocalApp.current
    val lib = app.lib
    var ageDays by rememberSaveable { mutableIntStateOf(90) }
    val old = lib.olderThan(ageDays)
    val biggest = lib.largest(BIGGEST)
    val dupes = lib.duplicateGroups
    val extra = dupes?.sumOf { it.size - 1 } ?: 0
    val extraSize = dupes?.sumOf { g -> g.drop(1).sumOf { it.size } } ?: 0L
    val unreviewed = lib.unreviewed

    val cards: List<@Composable () -> Unit> = listOf(
        { StorageHero() },
        {
            ToolCard(
                Icons.Rounded.Swipe, Brand.violet, "Swipe to clean",
                figure = if (unreviewed.isEmpty()) null else "${unreviewed.size}",
                caption = when {
                    lib.shots.isEmpty() -> "No screenshots yet."
                    unreviewed.isEmpty() -> "You've been through them all."
                    else -> "to go through. Left to delete, right to keep."
                },
                action = if (lib.shots.isEmpty()) null else {
                    {
                        PillButton(if (unreviewed.isEmpty()) "Start over" else "Start", {
                            if (unreviewed.isEmpty()) lib.resetReviewed()
                            app.openSwipe(lib.unreviewed)
                        }, height = 42.dp, expand = false)
                    }
                },
            )
        },
        {
            ToolCard(
                Icons.Rounded.CopyAll, Brand.violet, "Exact duplicates",
                figure = if (dupes.isNullOrEmpty()) null else formatBytes(extraSize),
                caption = when {
                    lib.scanningDuplicates -> "Comparing files…"
                    dupes == null -> "Find screenshots saved more than once, byte for byte."
                    dupes.isEmpty() -> "No duplicates. Nice and tidy!"
                    else -> "$extra extra ${if (extra == 1) "copy" else "copies"} you can let go"
                },
                progress = if (lib.scanningDuplicates) lib.duplicateProgress else null,
                action = when {
                    lib.scanningDuplicates -> null
                    dupes.isNullOrEmpty() -> {
                        {
                            PillButton(
                                if (dupes == null) "Scan" else "Scan again",
                                if (lib.shots.isEmpty()) null else lib::scanDuplicates,
                                style = PillStyle.Ink, height = 42.dp, expand = false,
                            )
                        }
                    }
                    else -> {
                        {
                            PillButton("Review", {
                                app.review(
                                    "Duplicates",
                                    { l -> l.duplicateGroups.orEmpty().map { g -> Section("${g.size} copies", g, formatBytes(g.first().size)) } },
                                    preselect = dupes.flatMap { g -> g.drop(1).map { it.id } }.toSet(),
                                    hint = "The oldest copy of each is kept. The extra copies are already selected.",
                                    empty = "No duplicates left.",
                                )
                            }, height = 42.dp, expand = false)
                        }
                    }
                },
            )
        },
        {
            ToolCard(
                Icons.Rounded.History, Brand.amber, "Old screenshots",
                figure = if (old.isEmpty()) null else formatBytes(old.sumOf { it.size }),
                caption = if (old.isEmpty()) "Nothing older than ${ages[ageDays]}."
                else "${formatCount(old.size, "screenshot")} older than ${ages[ageDays]}",
                extra = { PillTabs(ages.keys.toList(), { ages.getValue(it) }, ageDays, { ageDays = it }, height = 42.dp) },
                action = if (old.isEmpty()) null else {
                    {
                        PillButton("Review", {
                            val days = ageDays
                            app.review(
                                "Older than ${ages[days]}",
                                { l -> sectionsByDate(l.olderThan(days)) },
                                preselect = old.map { it.id }.toSet(),
                                hint = "All selected. Untick anything you want to keep.",
                            )
                        }, height = 42.dp, expand = false)
                    }
                },
            )
        },
        {
            ToolCard(
                Icons.Rounded.PhotoSizeSelectLarge, Brand.coral, "Biggest files",
                figure = if (biggest.isEmpty()) null else formatBytes(biggest.sumOf { it.size }),
                caption = if (biggest.isEmpty()) "No screenshots yet." else "taken up by your ${biggest.size} largest",
                action = if (biggest.isEmpty()) null else {
                    {
                        PillButton("Review", {
                            app.review("Biggest files", { l -> l.largest(BIGGEST).let { if (it.isEmpty()) emptyList() else listOf(Section("Largest first", it)) } })
                        }, height = 42.dp, expand = false)
                    }
                },
            )
        },
    )

    LazyColumn(
        Modifier.fillMaxSize(),
        state = rememberLazyListState(),
        contentPadding = PaddingValues(horizontal = Insets.page),
        verticalArrangement = Arrangement.spacedBy(Insets.gap),
    ) {
        item("title") {
            Column(Modifier.padding(bottom = 10.dp)) { TabTitle("Clean", "up.", "Free up space") }
        }
        cards.forEachIndexed { i, card ->
            item("card$i") {
                Column(Modifier.entrance(delayMs = 70 * i, fromY = 16.dp, durationMs = 500)) { card() }
            }
        }
        item("navSpace") {
            Spacer(Modifier.windowInsetsPadding(WindowInsets.navigationBars).height(Insets.navClearance - Insets.gap))
        }
    }
}

/** Dark card: total size, split by app. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun StorageHero() {
    val app = LocalApp.current
    val lib = app.lib
    val t = tokens
    val total = lib.totalSize
    val top = lib.apps.sortedByDescending { it.totalSize }.filter { it.name != Shot.OTHER }.take(4)
    val rest = total - top.sumOf { it.totalSize }
    val (value, unit) = when {
        total < 1024L * 1024 -> total / 1024.0 to "KB"
        total < 1024L * 1024 * 1024 -> total / (1024.0 * 1024) to "MB"
        else -> total / (1024.0 * 1024 * 1024) to "GB"
    }
    val white = Color.White
    val shape = RoundedCornerShape(Insets.radius)
    Column(
        Modifier.fillMaxWidth().background(t.hero, shape)
            .then(if (t.dark) Modifier.border(1.dp, t.border, shape) else Modifier)
            .padding(start = 22.dp, top = 22.dp, end = 22.dp, bottom = 20.dp),
    ) {
        Text("SCREENSHOTS TAKE UP", Type.overline, color = white.copy(alpha = 0.55f))
        Spacer(Modifier.height(10.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            CountUp(
                value.toFloat(),
                { fixed(it.toDouble(), if (value >= 100) 0 else 1) },
                Type.display.copy(fontSize = 54.sp, letterSpacing = (-2.4).sp, lineHeight = 58.sp),
                white,
            )
            Spacer(Modifier.width(8.dp))
            Text(unit, serif(30f, white.copy(alpha = 0.75f)), Modifier.padding(bottom = 8.dp))
        }
        Spacer(Modifier.height(4.dp))
        Text(
            if (lib.shots.isEmpty()) "No screenshots yet"
            else "${formatCount(lib.shots.size, "screenshot")} since ${shortDate(lib.shots.last().date)}",
            Type.body, color = white.copy(alpha = 0.65f),
        )
        if (total > 0) {
            Spacer(Modifier.height(20.dp))
            SegmentBar(
                top.map { it.totalSize.toFloat() / total to colorFor(it.name) } +
                    (if (rest > 0) listOf(rest.toFloat() / total to white.copy(alpha = 0.3f)) else emptyList()),
                height = 14.dp,
                track = white.copy(alpha = 0.1f),
            )
            Spacer(Modifier.height(14.dp))
            FlowRow(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                for (g in top) Legend(colorFor(g.name), g.name, formatBytes(g.totalSize)) { app.openApp(g.name) }
                if (rest > 0) Legend(white.copy(alpha = 0.3f), "Everything else", formatBytes(rest), null)
            }
        }
    }
}

@Composable
private fun Legend(color: Color, label: String, value: String, onClick: (() -> Unit)?) {
    Row(
        Modifier.combinedClickable(interactionSource = null, indication = null, enabled = onClick != null) { onClick?.invoke() },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Dot(color)
        Spacer(Modifier.width(6.dp))
        Text(label, Type.labelMedium, Modifier.widthIn(max = 160.dp), color = Color.White, maxLines = 1)
        Spacer(Modifier.width(5.dp))
        Text(value, Type.labelMedium.copy(fontWeight = FontWeight.SemiBold), color = Color.White.copy(alpha = 0.5f), maxLines = 1)
    }
}

@Composable
private fun ToolCard(
    icon: ImageVector,
    color: Color,
    title: String,
    caption: String,
    figure: String? = null,
    action: (@Composable () -> Unit)? = null,
    extra: (@Composable () -> Unit)? = null,
    progress: Float? = null,
) {
    val t = tokens
    Panel(padding = PaddingValues(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBadge(icon, color)
            Spacer(Modifier.width(14.dp))
            Text(title, Type.title, Modifier.weight(1f))
        }
        if (extra != null) {
            Spacer(Modifier.height(16.dp))
            extra()
        }
        Spacer(Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.Bottom) {
            Column(Modifier.weight(1f)) {
                if (figure != null) Text(figure, Type.headlineMedium.copy(fontSize = 34.sp, lineHeight = 38.sp), maxLines = 1)
                Text(caption, Type.body, color = t.muted)
            }
            if (action != null) {
                Spacer(Modifier.width(12.dp))
                action()
            }
        }
        if (progress != null) {
            Spacer(Modifier.height(12.dp))
            ProgressBar(progress, color = color)
        }
    }
}

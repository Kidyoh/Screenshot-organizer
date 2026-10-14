package com.kidyoh.snapsort.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Apps
import androidx.compose.material.icons.automirrored.rounded.ManageSearch
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.formatBytes
import com.kidyoh.snapsort.data.formatCount
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.Dot
import com.kidyoh.snapsort.ui.EmptyState
import com.kidyoh.snapsort.ui.FannedStack
import com.kidyoh.snapsort.ui.Icon
import com.kidyoh.snapsort.ui.IconBadge
import com.kidyoh.snapsort.ui.Insets
import com.kidyoh.snapsort.ui.Loading
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.PageTitle
import com.kidyoh.snapsort.ui.Panel
import com.kidyoh.snapsort.ui.PillButton
import com.kidyoh.snapsort.ui.PillStyle
import com.kidyoh.snapsort.ui.PillTabs
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.colorFor
import com.kidyoh.snapsort.ui.entrance
import com.kidyoh.snapsort.ui.tokens
import kotlin.math.ceil

private enum class AppSort(val label: String) { Most("Most"), Size("Biggest"), Name("A–Z") }

/** A two-up grid of cards, used by the Apps and Albums tabs. */
@Composable
fun CardGrid(content: LazyGridScope.() -> Unit) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val columns = ceil((maxWidth - Insets.page * 2).value / (220f + 12f)).toInt().coerceAtLeast(2)
        LazyVerticalGrid(
            GridCells.Fixed(columns),
            Modifier.fillMaxSize(),
            state = rememberLazyGridState(),
            contentPadding = PaddingValues(horizontal = Insets.page),
            horizontalArrangement = Arrangement.spacedBy(Insets.gap),
            verticalArrangement = Arrangement.spacedBy(Insets.gap),
            content = content,
        )
    }
}

/** A full-width item in a [CardGrid]. */
fun LazyGridScope.row(key: Any, content: @Composable () -> Unit) =
    item(key = key, span = { GridItemSpan(maxLineSpan) }) { content() }

fun LazyGridScope.navSpace() = row("navSpace") {
    Spacer(Modifier.windowInsetsPadding(WindowInsets.navigationBars).height(Insets.navClearance - Insets.gap))
}

/** Tab title with the status bar inset above it. */
@Composable
fun TabTitle(lead: String, accent: String, overline: String?) {
    PageTitle(
        lead, accent, overline,
        modifier = Modifier.windowInsetsPadding(WindowInsets.statusBars).padding(start = 2.dp, top = 30.dp).entrance(),
    )
}

/** Screenshots grouped by the app they were taken in. */
@Composable
fun AppsScreen() {
    val app = LocalApp.current
    val lib = app.lib
    var sort by rememberSaveable { mutableStateOf(AppSort.Most) }
    val apps = when (sort) {
        AppSort.Most -> lib.apps // most screenshots first, "Other" last
        AppSort.Size -> lib.apps.sortedByDescending { it.totalSize }
        AppSort.Name -> lib.apps.sortedBy { it.name.lowercase() }
    }

    CardGrid {
        row("title") {
            TabTitle(
                "Sorted by", "app.",
                when {
                    !lib.loadedOnce -> null
                    lib.recognising -> "${formatCount(apps.size, "app")} · recognising more…"
                    else -> formatCount(apps.size, "app")
                },
            )
        }
        if (apps.isNotEmpty()) {
            row("sort") {
                Box(Modifier.padding(top = 10.dp)) {
                    PillTabs(AppSort.entries, { it.label }, sort, { sort = it })
                }
            }
        }
        if (lib.unknownCount > 0 && !lib.usageAccess && !lib.usageCardDismissed) {
            row("usage") { UsageCard(lib.unknownCount) }
        }
        if (apps.isEmpty()) {
            row("empty") {
                if (lib.loadedOnce) EmptyState(Icons.Rounded.Apps, "No apps yet", "Your screenshots get grouped here by the app you took them in.")
                else Loading()
            }
        } else {
            itemsIndexed(apps, key = { _, g -> g.name }) { i, g ->
                GroupCard(
                    g.name, g.shots, "${g.shots.size} · ${formatBytes(g.totalSize)}",
                    onClick = { app.openApp(g.name) },
                    modifier = Modifier.entrance(delayMs = 40 * (i % 10), fromY = 14.dp, durationMs = 400),
                )
            }
        }
        navSpace()
    }
}

/** A tinted card with a fanned stack of screenshots, for apps and albums. */
@Composable
fun GroupCard(
    name: String,
    shots: List<Shot>,
    detail: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    onLongClick: (() -> Unit)? = null,
    icon: ImageVector? = null,
) {
    val t = tokens
    val color = colorFor(name)
    Panel(modifier.aspectRatio(0.8f), padding = PaddingValues(8.dp), onClick = onClick, onLongClick = onLongClick) {
        Box(
            Modifier.weight(1f).fillMaxWidth().background(t.wash(color), RoundedCornerShape(Insets.radius - 8.dp)),
            contentAlignment = Alignment.Center,
        ) {
            if (shots.isEmpty() && icon != null) Icon(icon, color, size = 40.dp)
            else ScaledToFit { FannedStack(shots) }
        }
        Column(Modifier.padding(start = 8.dp, top = 12.dp, end = 8.dp, bottom = 6.dp)) {
            Text(name, Type.title, maxLines = 1)
            Spacer(Modifier.height(3.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Dot(color, 7.dp)
                Spacer(Modifier.width(7.dp))
                Text(detail, Type.bodySmall, color = t.muted, maxLines = 1)
            }
        }
    }
}

/** Scales its content down (never up) to fit, like Flutter's FittedBox. */
@Composable
fun ScaledToFit(content: @Composable () -> Unit) {
    androidx.compose.ui.layout.Layout(content, Modifier.fillMaxSize()) { measurables, constraints ->
        val p = measurables.first().measure(androidx.compose.ui.unit.Constraints())
        val scale = minOf(1f, constraints.maxWidth.toFloat() / p.width, constraints.maxHeight.toFloat() / p.height)
        layout(constraints.maxWidth, constraints.maxHeight) {
            p.placeWithLayer((constraints.maxWidth - p.width) / 2, (constraints.maxHeight - p.height) / 2) {
                scaleX = scale
                scaleY = scale
            }
        }
    }
}

/** Offers Usage access when screenshots don't say which app they're from. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun UsageCard(count: Int) {
    val lib = LocalApp.current.lib
    Panel(padding = PaddingValues(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconBadge(Icons.AutoMirrored.Rounded.ManageSearch, Brand.violet)
            Spacer(Modifier.width(14.dp))
            Text("Find the app for ${formatCount(count, "screenshot")}", Type.title, Modifier.weight(1f))
        }
        Spacer(Modifier.height(12.dp))
        Text(
            "Your phone didn't write the app into their names. With Usage access on, SnapSort checks which app " +
                "was open when each one was taken. It stays on your phone.",
            Type.body, color = tokens.muted,
        )
        Spacer(Modifier.height(16.dp))
        FlowRow(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PillButton("Turn on", lib::openUsageAccess, height = 44.dp, expand = false)
            PillButton("Not now", lib::dismissUsageCard, style = PillStyle.Soft, height = 44.dp, expand = false)
        }
    }
}

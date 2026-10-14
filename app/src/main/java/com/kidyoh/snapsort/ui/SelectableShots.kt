package com.kidyoh.snapsort.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.outlined.PhotoAlbum
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Deselect
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FavoriteBorder
import androidx.compose.material.icons.rounded.IosShare
import androidx.compose.material.icons.automirrored.rounded.Label
import androidx.compose.material.icons.rounded.RemoveCircleOutline
import androidx.compose.material.icons.rounded.SelectAll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import com.kidyoh.snapsort.data.Section
import com.kidyoh.snapsort.data.Shot
import kotlin.math.ceil

private val GridSide = Insets.page - 4.dp

/** Lets a full-width item ignore the grid's side padding. */
fun Modifier.fullBleed(side: Dp = GridSide) = layout { measurable, constraints ->
    val extra = side.roundToPx() * 2
    val placeable = measurable.measure(
        constraints.copy(
            minWidth = (constraints.minWidth + extra).coerceAtLeast(0),
            maxWidth = constraints.maxWidth + extra,
        ),
    )
    layout(constraints.maxWidth, placeable.height) { placeable.place(-extra / 2, 0) }
}

/** A full-width row in a grid. */
fun LazyGridScope.wide(key: Any? = null, content: @Composable () -> Unit) =
    item(key = key, span = { GridItemSpan(maxLineSpan) }) { Box(Modifier.fullBleed()) { content() } }

/**
 * A scrolling page of sectioned screenshots with long-press multi-select,
 * a top selection bar and a floating action dock.
 */
@Composable
fun SelectableShots(
    sections: List<Section>,
    header: LazyGridScope.() -> Unit,
    modifier: Modifier = Modifier,
    leading: LazyGridScope.() -> Unit = {},
    empty: (@Composable () -> Unit)? = null,
    initialSelection: Set<Long> = emptySet(),
    album: String? = null,
    inTab: Boolean = false,
    onSelecting: (Boolean) -> Unit = {},
) {
    val app = LocalApp.current
    val lib = app.lib
    val selection = remember { Selection(initialSelection) }
    val visible = remember(sections) { sections.flatMap { it.shots } }
    val selected = selection.ids.mapNotNull { lib.byId(it) }
    val selecting = selected.isNotEmpty()
    LaunchedEffect(selecting) { onSelecting(selecting) }
    BackHandler(enabled = selecting) { selection.clear() }

    Box(modifier.fillMaxSize()) {
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val columns = ceil(((maxWidth - GridSide * 2).value) / (140f + 6f)).toInt().coerceAtLeast(2)
            LazyVerticalGrid(
                GridCells.Fixed(columns),
                Modifier.fillMaxSize(),
                state = rememberLazyGridState(),
                contentPadding = PaddingValues(horizontal = GridSide),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                header()
                leading()
                if (visible.isEmpty() && empty != null) {
                    wide("empty") { empty() }
                } else {
                    for (section in sections) {
                        wide("h-${section.title}-${section.shots.firstOrNull()?.id}") { SectionHeader(section, selection) }
                        items(section.shots, key = { it.id }) { shot ->
                            ShotTile(
                                shot, selection, shot.id in lib.favorites,
                                onOpen = { app.push(ViewerRoute(visible, visible.indexOf(shot))) },
                                modifier = Modifier.aspectRatio(0.56f),
                            )
                        }
                    }
                }
                wide("bottom") {
                    Spacer(
                        Modifier.windowInsetsPadding(WindowInsets.navigationBars)
                            .height((if (inTab) Insets.navClearance else 40.dp) + if (selecting) 40.dp else 0.dp),
                    )
                }
            }
        }

        // Top selection bar
        AnimatedVisibility(
            selecting,
            modifier = Modifier.align(Alignment.TopCenter),
            enter = slideInVertically(tween(300, easing = FastOutSlowInEasing)) { -it },
            exit = slideOutVertically(tween(300)) { -it },
        ) {
            val allSelected = visible.isNotEmpty() && visible.all { it in selection }
            SelectionBar(selected.size.coerceAtLeast(1), allSelected, onClose = selection::clear) {
                selection.setAll(visible, !allSelected)
            }
        }

        // Bottom dock
        AnimatedVisibility(
            selecting,
            modifier = Modifier.align(Alignment.BottomCenter),
            enter = slideInVertically(tween(340, easing = FastOutSlowInEasing)) { it * 2 },
            exit = slideOutVertically(tween(340)) { it * 2 },
        ) {
            val allFavorite = selected.isNotEmpty() && selected.all(lib::isFavorite)
            val actions = buildList {
                add(DockAction(Icons.Outlined.PhotoAlbum, "Album") { app.scope.launch { if (app.addToAlbum(selected)) selection.clear() } })
                add(DockAction(Icons.AutoMirrored.Rounded.Label, "Set app") { app.scope.launch { if (app.setAppFor(selected)) selection.clear() } })
                add(DockAction(Icons.Rounded.IosShare, "Share") { lib.share(selected) })
                add(
                    DockAction(if (allFavorite) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder, if (allFavorite) "Unlike" else "Favorite") {
                        lib.setFavorite(selected, !allFavorite)
                        selection.clear()
                    },
                )
                if (album != null) {
                    add(DockAction(Icons.Rounded.RemoveCircleOutline, "Remove") {
                        lib.removeFromAlbum(album, selected)
                        selection.clear()
                    })
                }
                add(DockAction(Icons.Rounded.Delete, "Delete", danger = true) {
                    app.scope.launch { if (app.deleteShots(selected)) selection.clear() }
                })
            }
            SelectionDock(
                actions,
                Modifier.windowInsetsPadding(WindowInsets.navigationBars).padding(start = Insets.page, end = Insets.page, bottom = 18.dp),
            )
        }
    }
}

@Composable
private fun SelectionBar(count: Int, allSelected: Boolean, onClose: () -> Unit, onToggleAll: () -> Unit) {
    val t = tokens
    Row(
        Modifier.fillMaxWidth().background(t.canvas).windowInsetsPadding(WindowInsets.statusBars)
            .padding(start = Insets.page, top = 10.dp, end = Insets.page, bottom = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CircleButton(Icons.Rounded.Close, "Clear selection", onClose)
        Spacer(Modifier.width(14.dp))
        AnimatedContent(count, Modifier.weight(1f), transitionSpec = { fadeIn(tween(160)) togetherWith fadeOut(tween(100)) }, label = "count") { n ->
            Text(accented("$n", "selected", 26f, t.highlight), Type.headline.copy(fontSize = 26.sp), maxLines = 1)
        }
        PillButton(
            if (allSelected) "None" else "All",
            onToggleAll,
            icon = if (allSelected) Icons.Rounded.Deselect else Icons.Rounded.SelectAll,
            style = PillStyle.Soft,
            height = 42.dp,
            expand = false,
        )
    }
}

/** Standard top of a pushed page: back button, actions, then the title. */
fun LazyGridScope.pageHeader(
    title: String,
    overline: String? = null,
    subtitle: String? = null,
    dot: Color? = null,
    actions: @Composable () -> Unit = {},
) {
    wide("pageHeader") {
        val app = LocalApp.current
        val t = tokens
        Column {
            Row(
                Modifier.windowInsetsPadding(WindowInsets.statusBars).padding(start = Insets.page, top = 10.dp, end = Insets.page),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircleButton(Icons.AutoMirrored.Rounded.ArrowBack, "Back", app::pop)
                Spacer(Modifier.weight(1f))
                actions()
            }
            Column(Modifier.padding(start = Insets.page + 2.dp, top = 22.dp, end = Insets.page).entrance(durationMs = 350)) {
                if (overline != null) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (dot != null) {
                            Dot(dot, 9.dp)
                            Spacer(Modifier.width(8.dp))
                        }
                        SectionLabel(overline)
                    }
                }
                Spacer(Modifier.height(6.dp))
                Text(title, Type.display.copy(fontSize = 36.sp), maxLines = 2)
                if (subtitle != null) {
                    Spacer(Modifier.height(6.dp))
                    Text(subtitle, Type.body, color = t.muted)
                }
            }
        }
    }
}


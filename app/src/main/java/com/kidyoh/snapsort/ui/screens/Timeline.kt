package com.kidyoh.snapsort.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.ScreenshotMonitor
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.SearchOff
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.Thumbs
import com.kidyoh.snapsort.data.formatCount
import com.kidyoh.snapsort.data.greeting
import com.kidyoh.snapsort.data.sectionsByDate
import com.kidyoh.snapsort.data.shortDate
import com.kidyoh.snapsort.data.startOfDay
import com.kidyoh.snapsort.data.timeOfDay
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.CircleButton
import com.kidyoh.snapsort.ui.EmptyState
import com.kidyoh.snapsort.ui.GlassTag
import com.kidyoh.snapsort.ui.Icon
import com.kidyoh.snapsort.ui.IconBadge
import com.kidyoh.snapsort.ui.Insets
import com.kidyoh.snapsort.ui.Loading
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.PageTitle
import com.kidyoh.snapsort.ui.Panel
import com.kidyoh.snapsort.ui.PillFilters
import com.kidyoh.snapsort.ui.RoundedShot
import com.kidyoh.snapsort.ui.SectionLabel
import com.kidyoh.snapsort.ui.SelectableShots
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.ViewerRoute
import com.kidyoh.snapsort.ui.colorFor
import com.kidyoh.snapsort.ui.entrance
import com.kidyoh.snapsort.ui.floating
import com.kidyoh.snapsort.ui.pressable
import com.kidyoh.snapsort.ui.raised
import com.kidyoh.snapsort.ui.serif
import com.kidyoh.snapsort.ui.tokens
import com.kidyoh.snapsort.ui.wide

/** Every screenshot, newest first: a "Latest" rail, app filters and a sectioned grid. */
@Composable
fun TimelineScreen(onSelecting: (Boolean) -> Unit) {
    val app = LocalApp.current
    val lib = app.lib
    val t = tokens
    var searching by rememberSaveable { mutableStateOf(false) }
    var query by rememberSaveable { mutableStateOf("") }
    var filter by rememberSaveable { mutableStateOf<String?>(null) }
    val focus = LocalFocusManager.current

    fun toggleSearch() {
        searching = !searching
        query = ""
        if (!searching) focus.clearFocus()
    }
    BackHandler(enabled = searching) { toggleSearch() }

    var shots = if (searching) lib.search(query) else lib.shots
    filter?.let { f -> shots = shots.filter { it.app == f } }
    val showRail = !searching && filter == null && lib.shots.size >= 4
    val latest = if (showRail) lib.shots.take(8) else emptyList()
    val sections = remember(shots) { sectionsByDate(shots) }

    SelectableShots(
        sections = sections,
        inTab = true,
        onSelecting = onSelecting,
        header = {
            wide("top") {
                Box(Modifier.windowInsetsPadding(WindowInsets.statusBars).padding(start = Insets.page, top = 10.dp, end = Insets.page)) {
                    AnimatedContent(searching, transitionSpec = { fadeIn(tween(260)) togetherWith fadeOut(tween(200)) }, label = "search") { s ->
                        if (s) {
                            SearchField(query, { query = it }, ::toggleSearch)
                        } else {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("snapsort", serif(26f, t.ink), Modifier.weight(1f), maxLines = 1)
                                CircleButton(Icons.Rounded.Search, "Search", ::toggleSearch)
                                Spacer(Modifier.width(10.dp))
                                CircleButton(Icons.Rounded.Tune, "Settings", { app.showSettings() })
                            }
                        }
                    }
                }
            }
            if (!searching) {
                wide("title") {
                    PageTitle(
                        overline = if (lib.loadedOnce) "${greeting()} · ${formatCount(lib.shots.size, "screenshot")}" else "Reading your screenshots…",
                        lead = "Your",
                        accent = "screenshots.",
                        modifier = Modifier.padding(start = Insets.page + 2.dp, top = 26.dp, end = Insets.page, bottom = 4.dp).entrance(),
                    )
                }
            }
        },
        leading = {
            if (lib.isLimited) {
                wide("limited") {
                    Panel(Modifier.padding(start = Insets.page, top = 18.dp, end = Insets.page), onClick = { lib.askForAccess() }) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            IconBadge(Icons.Rounded.Lock, Brand.amber)
                            Spacer(Modifier.width(14.dp))
                            Column(Modifier.weight(1f)) {
                                Text("SnapSort sees only some photos", Type.titleSmall)
                                Text("Tap to allow all of them", Type.bodySmall, color = t.muted)
                            }
                            Icon(Icons.Rounded.ChevronRight, t.faint)
                        }
                    }
                }
            }
            if (latest.isNotEmpty()) {
                wide("latestLabel") { SectionLabel("Latest", Modifier.padding(start = Insets.page + 2.dp, top = 28.dp, bottom = 14.dp)) }
                wide("latest") { LatestRail(latest) }
            }
            if (lib.apps.size > 1 && !searching) {
                wide("filters") {
                    Box(Modifier.padding(top = 22.dp)) {
                        PillFilters(
                            listOf(Triple<String?, String, Int?>(null, "All", null)) +
                                lib.apps.take(12).map { Triple(it.name, it.name, it.shots.size) },
                            filter,
                        ) { filter = it }
                    }
                }
            }
        },
        empty = {
            when {
                !lib.loadedOnce -> Loading()
                latest.isNotEmpty() -> Spacer(Modifier.height(1.dp))
                searching || filter != null -> EmptyState(Icons.Rounded.SearchOff, "No matches", "Try another app name, file name or month.")
                else -> EmptyState(
                    Icons.Rounded.ScreenshotMonitor, "No screenshots yet",
                    "SnapSort reads your phone's Screenshots folder. Take one and it shows up here.",
                )
            }
        },
    )
}

@Composable
private fun SearchField(query: String, onChange: (String) -> Unit, onClose: () -> Unit) {
    val t = tokens
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Row(
            Modifier.weight(1f).height(50.dp).raised(RoundedCornerShape(50), t).background(t.card, RoundedCornerShape(50)).padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Rounded.Search, t.muted, size = 22.dp)
            Spacer(Modifier.width(10.dp))
            Box(Modifier.weight(1f)) {
                if (query.isEmpty()) Text("App, file name or month", Type.titleSmall, color = t.faint, maxLines = 1)
                BasicTextField(
                    query, onChange,
                    Modifier.fillMaxWidth().focusRequester(focus),
                    textStyle = Type.titleSmall.copy(color = t.ink),
                    singleLine = true,
                    cursorBrush = SolidColor(t.highlight),
                )
            }
        }
        Spacer(Modifier.width(10.dp))
        CircleButton(Icons.Rounded.Close, "Close search", onClose)
    }
}

/** Big swipeable cards for the newest screenshots. */
@Composable
private fun LatestRail(shots: List<Shot>) {
    val app = LocalApp.current
    val t = tokens
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val cardW = (maxWidth * 0.4f).coerceIn(140.dp, 200.dp)
        val state = rememberLazyListState()
        LazyRow(
            Modifier.fillMaxWidth().height(cardW * 1.72f + 24.dp),
            state = state,
            flingBehavior = rememberSnapFlingBehavior(state),
            contentPadding = PaddingValues(start = Insets.page, end = Insets.page, bottom = 24.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            itemsIndexed(shots, key = { _, s -> s.id }) { i, s ->
                val shape = RoundedCornerShape(26.dp)
                Box(
                    Modifier
                        .entrance(delayMs = 90 * i, fromY = 0.dp, fromX = 24.dp, durationMs = 600)
                        .size(cardW, cardW * 1.72f)
                        .pressable({ app.push(ViewerRoute(shots, i)) }, scale = 0.97f)
                        .floating(shape, t, blur = 24.dp)
                ) {
                    RoundedShot(s, Modifier.fillMaxSize(), 26.dp, Thumbs.THUMB * 2)
                    GlassTag(s.app, colorFor(s.app), Modifier.align(Alignment.TopStart).padding(10.dp).widthIn(max = 140.dp))
                    GlassTag(whenTaken(s.date), null, Modifier.align(Alignment.BottomStart).padding(10.dp))
                }
            }
        }
    }
}

private fun whenTaken(d: Long): String {
    val now = System.currentTimeMillis()
    return when {
        d >= startOfDay(now) -> "Today, ${timeOfDay(d)}"
        d >= startOfDay(now, 1) -> "Yesterday"
        else -> shortDate(d)
    }
}

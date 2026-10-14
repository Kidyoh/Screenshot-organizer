package com.kidyoh.snapsort.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.InsertDriveFile
import androidx.compose.material.icons.automirrored.rounded.OpenInNew
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.PhotoAlbum
import androidx.compose.material.icons.rounded.Apps
import androidx.compose.material.icons.rounded.AspectRatio
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Event
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FavoriteBorder
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.IosShare
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.Thumbs
import com.kidyoh.snapsort.data.formatBytes
import com.kidyoh.snapsort.data.longDate
import com.kidyoh.snapsort.data.shortDate
import com.kidyoh.snapsort.data.timeOfDay
import com.kidyoh.snapsort.ui.AppState
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.Dot
import com.kidyoh.snapsort.ui.Glass
import com.kidyoh.snapsort.ui.GlassButton
import com.kidyoh.snapsort.ui.Icon
import com.kidyoh.snapsort.ui.IconBadge
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.PillButton
import com.kidyoh.snapsort.ui.PillStyle
import com.kidyoh.snapsort.ui.SheetHeading
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.ViewerRoute
import com.kidyoh.snapsort.ui.addToAlbum
import com.kidyoh.snapsort.ui.appSourceText
import com.kidyoh.snapsort.ui.colorFor
import com.kidyoh.snapsort.ui.deleteShots
import com.kidyoh.snapsort.ui.entrance
import com.kidyoh.snapsort.ui.rememberHaptics
import com.kidyoh.snapsort.ui.rememberShotImage
import com.kidyoh.snapsort.ui.serif
import com.kidyoh.snapsort.ui.setAppFor
import com.kidyoh.snapsort.ui.tokens
import kotlinx.coroutines.launch
import kotlin.math.abs

/** Full-screen, swipeable, pinch-to-zoom viewer. Swipe down to close. */
@Composable
fun ViewerScreen(route: ViewerRoute) {
    val app = LocalApp.current
    val lib = app.lib
    val haptics = rememberHaptics()
    val scope = rememberCoroutineScope()
    val items = remember { route.shots.toMutableStateList() }
    val pager = rememberPagerState(route.index.coerceIn(0, (items.size - 1).coerceAtLeast(0))) { items.size }
    var chrome by remember { mutableStateOf(true) }
    var zoomed by remember { mutableStateOf(false) }
    val drag = remember { Animatable(0f) }
    val density = LocalDensity.current

    if (items.isEmpty()) {
        Box(Modifier.fillMaxSize().background(Color.Black))
        return
    }
    val shot = items[pager.currentPage.coerceIn(0, items.lastIndex)]
    val favorite = lib.isFavorite(shot)
    val fade = (1 - abs(drag.value) / with(density) { 300.dp.toPx() }).coerceIn(0f, 1f)
    val showChrome = chrome && drag.value == 0f

    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = fade))) {
        HorizontalPager(
            pager,
            Modifier
                .fillMaxSize()
                .draggable(
                    rememberDraggableState { d -> scope.launch { drag.snapTo(drag.value + d) } },
                    Orientation.Vertical,
                    enabled = !zoomed,
                    onDragStopped = { v ->
                        if (abs(drag.value) > with(density) { 110.dp.toPx() } || abs(v) > 900f) app.pop()
                        else drag.animateTo(0f)
                    },
                )
                .graphicsLayer {
                    translationY = drag.value
                    val s = 1 - (abs(drag.value) / 2400f).coerceIn(0f, 0.12f)
                    scaleX = s
                    scaleY = s
                },
            userScrollEnabled = !zoomed,
            key = { items[it].id },
            beyondViewportPageCount = 1,
        ) { page ->
            ZoomableShot(
                items[page],
                onTap = { chrome = !chrome },
                onZoom = { if (page == pager.currentPage) zoomed = it },
            )
        }

        // Top bar
        Fade(showChrome, Modifier.align(Alignment.TopCenter)) {
            Row(
                Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.statusBars).padding(start = 16.dp, top = 10.dp, end = 16.dp)
                    .entrance(200, 0.dp, 350),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                GlassButton(Icons.Rounded.Close, "Close", app::pop)
                Spacer(Modifier.weight(1f))
                Glass(radius = 20.dp, padding = PaddingValues(horizontal = 14.dp, vertical = 10.dp)) {
                    Text("${pager.currentPage + 1} / ${items.size}", Type.labelMedium, color = Color.White)
                }
                Spacer(Modifier.width(10.dp))
                GlassButton(Icons.Rounded.Info, "Details", { scope.launch { app.showDetails(shot) } })
                Spacer(Modifier.width(10.dp))
                GlassButton(Icons.AutoMirrored.Rounded.OpenInNew, "Open with", { lib.openWith(shot) })
            }
        }

        // Caption + actions
        Fade(showChrome, Modifier.align(Alignment.BottomCenter)) {
            Glass(
                Modifier.windowInsetsPadding(WindowInsets.navigationBars).padding(start = 16.dp, end = 16.dp, bottom = 20.dp)
                    .fillMaxWidth().entrance(250, 40.dp, 450),
                radius = 30.dp,
                padding = PaddingValues(start = 20.dp, top = 14.dp, end = 10.dp, bottom = 10.dp),
            ) {
                Column(Modifier.fillMaxWidth()) {
                    AnimatedContent(shot.id, transitionSpec = { fadeIn(tween(220)) togetherWith fadeOut(tween(160)) }, label = "caption") { _ ->
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Dot(colorFor(shot.app), 9.dp)
                            Spacer(Modifier.width(9.dp))
                            Text(shot.app, Type.title, Modifier.weight(1f), color = Color.White, maxLines = 1)
                            Text("${shortDate(shot.date)}, ${timeOfDay(shot.date)}", serif(17f, Color.White.copy(alpha = 0.8f)), maxLines = 1)
                            Spacer(Modifier.width(10.dp))
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    Row {
                        Action(if (favorite) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder, "Favorite", if (favorite) Brand.coral else Color.White) {
                            haptics.light()
                            lib.setFavorite(listOf(shot), !favorite)
                        }
                        Action(Icons.Outlined.PhotoAlbum, "Album") { scope.launch { app.addToAlbum(listOf(shot)) } }
                        Action(Icons.Rounded.IosShare, "Share") { lib.share(listOf(shot)) }
                        Action(Icons.Rounded.Delete, "Delete") {
                            scope.launch {
                                if (app.deleteShots(listOf(shot))) {
                                    items.remove(shot)
                                    if (items.isEmpty()) app.pop()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Fade(visible: Boolean, modifier: Modifier, content: @Composable () -> Unit) {
    AnimatedVisibility(visible, modifier, enter = fadeIn(tween(200)), exit = fadeOut(tween(200))) { content() }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.Action(icon: ImageVector, label: String, color: Color = Color.White, onClick: () -> Unit) {
    Column(
        Modifier.weight(1f).semantics { contentDescription = label }
            .combinedClickable(interactionSource = null, indication = null, onClick = onClick)
            .padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, color)
        Spacer(Modifier.height(4.dp))
        Text(label, Type.labelMedium.copy(fontSize = 11.5.sp), color = Color.White.copy(alpha = 0.75f), maxLines = 1)
    }
}

/** One page: the screenshot, pinch or double-tap to zoom, pan while zoomed. */
@Composable
private fun ZoomableShot(shot: Shot, onTap: () -> Unit, onZoom: (Boolean) -> Unit) {
    var scale by remember { mutableFloatStateOf(1f) }
    var pan by remember { mutableStateOf(Offset.Zero) }
    var size by remember { mutableStateOf(IntSize.Zero) }
    val image = rememberShotImage(shot, Thumbs.FULL)

    fun clamp(p: Offset, s: Float): Offset {
        val maxX = (s - 1) * size.width / 2
        val maxY = (s - 1) * size.height / 2
        return Offset(p.x.coerceIn(-maxX, maxX), p.y.coerceIn(-maxY, maxY))
    }

    fun set(s: Float, p: Offset) {
        val z = s > 1.01f
        scale = s.coerceIn(1f, 6f)
        pan = if (z) clamp(p, scale) else Offset.Zero
        onZoom(z)
    }

    Box(
        Modifier
            .fillMaxSize()
            .onSizeChanged { size = it }
            .pointerInput(Unit) {
                detectTapGestures(
                    onTap = { onTap() },
                    onDoubleTap = { at ->
                        if (scale > 1.01f) set(1f, Offset.Zero)
                        else {
                            val s = 2.5f
                            val center = Offset(size.width / 2f, size.height / 2f)
                            set(s, (center - at) * (s - 1))
                        }
                    },
                )
            }
            .pointerInput(Unit) {
                awaitEachGesture {
                    awaitFirstDown(requireUnconsumed = false)
                    do {
                        val event = awaitPointerEvent()
                        val multi = event.changes.count { it.pressed } > 1
                        if (multi || scale > 1.01f) {
                            val zoom = event.calculateZoom()
                            val move = event.calculatePan()
                            set(scale * zoom, pan * zoom + move)
                            event.changes.forEach { if (it.positionChanged()) it.consume() }
                        }
                    } while (event.changes.any { it.pressed })
                }
            }
            .windowInsetsPadding(WindowInsets.statusBars)
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(start = 14.dp, top = 72.dp, end = 14.dp, bottom = 150.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .aspectRatio(shot.aspect, matchHeightConstraintsFirst = shot.aspect < 0.7f)
                .graphicsLayer {
                    scaleX = scale
                    scaleY = scale
                    translationX = pan.x
                    translationY = pan.y
                }
                .clip(RoundedCornerShape(22.dp)),
        ) {
            if (image != null) Image(image, null, Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
        }
    }
}

private suspend fun AppState.showDetails(s: Shot) {
    val change = sheets.show<Boolean> {
        val t = tokens
        @Composable
        fun row(icon: ImageVector, k: String, v: String, trailing: (@Composable () -> Unit)? = null) {
            Row(Modifier.padding(vertical = 9.dp), verticalAlignment = Alignment.CenterVertically) {
                IconBadge(icon, t.highlight, 40.dp)
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text(k, Type.bodySmall, color = t.muted)
                    Spacer(Modifier.height(2.dp))
                    SelectionContainer { Text(v.ifEmpty { "—" }, Type.titleSmall) }
                }
                trailing?.invoke()
            }
        }
        SheetHeading(s.app, "details")
        row(Icons.Rounded.Apps, "App · ${appSourceText(s.appSource)}", s.app) {
            PillButton("Change", { done(true) }, style = PillStyle.Soft, height = 40.dp, expand = false)
        }
        row(Icons.Rounded.Event, "Taken", "${longDate(s.date)} at ${timeOfDay(s.date)}")
        row(Icons.Rounded.AspectRatio, "Size", "${s.width} × ${s.height}  ·  ${formatBytes(s.size)}")
        row(Icons.AutoMirrored.Outlined.InsertDriveFile, "File", s.name)
        row(Icons.Outlined.Folder, "Folder", s.folder)
    }
    if (change == true) setAppFor(listOf(s))
}

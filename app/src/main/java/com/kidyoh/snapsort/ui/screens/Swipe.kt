package com.kidyoh.snapsort.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.VectorConverter
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.Undo
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kidyoh.snapsort.data.Section
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.Thumbs
import com.kidyoh.snapsort.data.formatBytes
import com.kidyoh.snapsort.data.formatCount
import com.kidyoh.snapsort.data.shortDate
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.CircleButton
import com.kidyoh.snapsort.ui.EmptyState
import com.kidyoh.snapsort.ui.FannedStack
import com.kidyoh.snapsort.ui.GlassTag
import com.kidyoh.snapsort.ui.GroupRoute
import com.kidyoh.snapsort.ui.Icon
import com.kidyoh.snapsort.ui.Insets
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.PillButton
import com.kidyoh.snapsort.ui.PillStyle
import com.kidyoh.snapsort.ui.ProgressBar
import com.kidyoh.snapsort.ui.SectionLabel
import com.kidyoh.snapsort.ui.ShotImage
import com.kidyoh.snapsort.ui.SwipeRoute
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.accented
import com.kidyoh.snapsort.ui.colorFor
import com.kidyoh.snapsort.ui.confirm
import com.kidyoh.snapsort.ui.deleteShots
import com.kidyoh.snapsort.ui.entrance
import com.kidyoh.snapsort.ui.floating
import com.kidyoh.snapsort.ui.pressable
import com.kidyoh.snapsort.ui.raised
import com.kidyoh.snapsort.ui.rememberHaptics
import com.kidyoh.snapsort.ui.tokens
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.min

private enum class Verdict { Delete, Keep, Favorite }

private class Step(val shot: Shot, val verdict: Verdict, val wasFavorite: Boolean)

/**
 * Tinder-style triage: swipe left to delete, right to keep, up to favorite.
 * Deletions are collected and done together at the end, so Android only asks once.
 */
@Composable
fun SwipeScreen(route: SwipeRoute) {
    val app = LocalApp.current
    val lib = app.lib
    val t = tokens
    val haptics = rememberHaptics()
    val scope = rememberCoroutineScope()
    val queue = remember { route.shots.toList() }
    val history = remember { mutableStateListOf<Step>() }
    val marked = remember { mutableStateListOf<Shot>() }
    var index by remember { mutableIntStateOf(0) }
    var finished by remember { mutableStateOf(false) }
    var flying by remember { mutableStateOf(false) }
    val offset = remember { Animatable(Offset.Zero, Offset.VectorConverter) }
    var area by remember { mutableStateOf(androidx.compose.ui.geometry.Size(300f, 600f)) }
    val done = finished || index >= queue.size
    val threshold = area.width * 0.28f

    fun verdictFor(o: Offset, velocityX: Float): Verdict? {
        val up = o.y < -area.height * 0.2f && abs(o.y) > abs(o.x)
        return when {
            up -> Verdict.Favorite
            o.x > threshold || velocityX > 900f -> Verdict.Keep
            o.x < -threshold || velocityX < -900f -> Verdict.Delete
            else -> null
        }
    }

    fun commit(verdict: Verdict) {
        val shot = queue[index]
        val wasFavorite = lib.isFavorite(shot)
        when (verdict) {
            Verdict.Delete -> { marked += shot; haptics.medium() }
            Verdict.Keep -> { lib.setReviewed(shot, true); haptics.light() }
            Verdict.Favorite -> {
                lib.setFavorite(listOf(shot), true)
                lib.setReviewed(shot, true)
                haptics.light()
            }
        }
        history += Step(shot, verdict, wasFavorite)
        index++
    }

    fun fling(verdict: Verdict) {
        if (flying || done) return
        flying = true
        scope.launch {
            val o = offset.value
            val target = when (verdict) {
                Verdict.Delete -> Offset(-area.width * 1.5f, o.y + 60f)
                Verdict.Keep -> Offset(area.width * 1.5f, o.y + 60f)
                Verdict.Favorite -> Offset(o.x, -area.height * 1.4f)
            }
            offset.animateTo(target, tween(240, easing = FastOutLinearInEasing))
            commit(verdict)
            offset.snapTo(Offset.Zero)
            flying = false
        }
    }

    fun undo() {
        if (history.isEmpty() || flying) return
        val step = history.removeAt(history.lastIndex)
        when (step.verdict) {
            Verdict.Delete -> marked.remove(step.shot)
            Verdict.Keep -> lib.setReviewed(step.shot, false)
            Verdict.Favorite -> {
                lib.setReviewed(step.shot, false)
                if (!step.wasFavorite) lib.setFavorite(listOf(step.shot), false)
            }
        }
        haptics.tick()
        finished = false
        index--
        scope.launch { offset.snapTo(Offset.Zero) }
    }

    fun leave() = scope.launch {
        if (marked.isEmpty() || app.confirm(
                "Leave", "without deleting?",
                "${formatCount(marked.size, "marked screenshot")} will stay on your phone.", "Leave", danger = false,
            )
        ) {
            marked.clear()
            app.pop()
        }
    }
    BackHandler { leave() }

    Column(
        Modifier.fillMaxSize().background(t.canvas)
            .windowInsetsPadding(WindowInsets.statusBars).windowInsetsPadding(WindowInsets.navigationBars)
            .padding(top = 10.dp, bottom = 18.dp),
    ) {
        // Header
        Column(Modifier.padding(start = Insets.page, end = Insets.page, bottom = 14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CircleButton(Icons.Rounded.Close, "Close", { leave() })
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    SectionLabel(route.title)
                    Spacer(Modifier.height(2.dp))
                    Text(
                        if (done) (if (index >= queue.size) "All done" else "Summary") else "${min(index, queue.size) + 1} of ${queue.size}",
                        Type.title,
                    )
                }
                if (!done && marked.isNotEmpty()) {
                    PillButton("${marked.size} · Finish", { finished = true }, style = PillStyle.Ink, height = 42.dp, expand = false)
                }
            }
            Spacer(Modifier.height(14.dp))
            ProgressBar(if (queue.isEmpty() || done) 1f else index.toFloat() / queue.size, height = 6.dp)
        }

        Box(Modifier.weight(1f).fillMaxWidth()) {
            if (done) {
                Summary(
                    marked, history.count { it.verdict != Verdict.Delete }, canContinue = index < queue.size,
                    onDelete = { scope.launch { if (app.deleteShots(marked.toList())) app.pop() } },
                    onReview = {
                        val ids = marked.map { it.id }.toSet()
                        app.pop()
                        app.push(
                            GroupRoute(
                                "Marked", "Review",
                                { l -> l.resolve(ids).let { if (it.isEmpty()) emptyList() else listOf(Section("Marked to delete", it)) } },
                                initialSelection = ids,
                                hint = "Untick any you want to keep, then tap Delete.",
                                emptyMessage = "Nothing left to delete.",
                            ),
                        )
                    },
                    onContinue = { finished = false },
                    onDone = { app.pop() },
                )
            } else {
                BoxWithConstraints(Modifier.fillMaxSize()) {
                    val density = LocalDensity.current
                    val measured = with(density) { androidx.compose.ui.geometry.Size(maxWidth.toPx(), maxHeight.toPx()) }
                    if (measured != area) area = measured
                    val cardW = min((maxWidth - Insets.page * 2).value, ((maxHeight - 30.dp) * 0.5f).value).dp
                    val cardH = min((maxHeight - 30.dp).value, (cardW * 2.05f).value).dp
                    val o = offset.value
                    val progress = (o.getDistance() / threshold).coerceIn(0f, 1f)
                    for (depth in 2 downTo 0) {
                        val i = index + depth
                        if (i >= queue.size) continue
                        val shot = queue[i]
                        androidx.compose.runtime.key(shot.id) {
                            if (depth == 0) {
                                SwipeCard(
                                    shot, cardW, cardH, o, threshold, area.height * 0.2f,
                                    Modifier
                                        .align(Alignment.TopCenter)
                                        .pointerInput(shot.id, area) {
                                            var armed = false
                                            var drag = Offset.Zero
                                            val tracker = VelocityTracker()
                                            detectDragGestures(
                                                onDragStart = {
                                                    tracker.resetTracking()
                                                    drag = offset.value
                                                },
                                                onDrag = { change, delta ->
                                                    if (flying) return@detectDragGestures
                                                    change.consume()
                                                    tracker.addPosition(change.uptimeMillis, change.position)
                                                    drag += delta
                                                    val target = drag
                                                    scope.launch { offset.snapTo(target) }
                                                    val nowArmed = verdictFor(drag, 0f) != null
                                                    if (nowArmed != armed) {
                                                        armed = nowArmed
                                                        if (nowArmed) haptics.tick()
                                                    }
                                                },
                                                onDragEnd = {
                                                    if (flying) return@detectDragGestures
                                                    armed = false
                                                    val v = tracker.calculateVelocity()
                                                    val verdict = verdictFor(drag, v.x)
                                                    if (verdict == null) {
                                                        scope.launch {
                                                            offset.animateTo(Offset.Zero, spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMediumLow))
                                                        }
                                                    } else fling(verdict)
                                                },
                                                onDragCancel = { scope.launch { offset.animateTo(Offset.Zero) } },
                                            )
                                        }
                                        .graphicsLayer {
                                            translationX = o.x
                                            translationY = o.y
                                            rotationZ = (o.x / area.width) * 0.32f * (180f / Math.PI.toFloat())
                                        },
                                )
                            } else {
                                // Cards behind grow into place as the top one moves away.
                                val d = depth - if (depth == 1) progress else progress * 0.5f
                                val y = with(density) { (22.dp * d).toPx() }
                                SwipeCard(
                                    shot, cardW, cardH, Offset.Zero, threshold, 1f,
                                    Modifier.align(Alignment.TopCenter).graphicsLayer {
                                        translationY = y
                                        scaleX = 1 - 0.05f * d
                                        scaleY = 1 - 0.05f * d
                                        transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0.5f, 0f)
                                    },
                                    dim = 0.06f * d,
                                )
                            }
                        }
                    }
                }
            }
        }

        if (!done) {
            val hintAlpha by animateFloatAsState(if (history.isEmpty() && offset.value == Offset.Zero) 1f else 0f, tween(250), label = "hint")
            Text(
                "Left to delete  ·  Right to keep  ·  Up to favorite",
                Type.bodySmall,
                Modifier.align(Alignment.CenterHorizontally).padding(top = 10.dp, bottom = 14.dp).graphicsLayer { alpha = hintAlpha },
                color = t.muted,
                maxLines = 1,
            )
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(18.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
                RoundAction(Icons.AutoMirrored.Rounded.Undo, "Undo", 52.dp, t.card, if (history.isEmpty()) t.faint else t.ink, if (history.isEmpty()) null else ::undo)
                RoundAction(Icons.Rounded.Close, "Delete", 72.dp, Brand.coral, Color.White) { fling(Verdict.Delete) }
                RoundAction(Icons.Rounded.Favorite, "Favorite", 58.dp, t.card, t.highlight) { fling(Verdict.Favorite) }
                RoundAction(Icons.Rounded.Check, "Keep", 72.dp, Brand.mint, Color.White) { fling(Verdict.Keep) }
            }
        }
    }
}

@Composable
private fun Summary(
    marked: List<Shot>,
    kept: Int,
    canContinue: Boolean,
    onDelete: () -> Unit,
    onReview: () -> Unit,
    onContinue: () -> Unit,
    onDone: () -> Unit,
) {
    val t = tokens
    if (marked.isEmpty()) {
        EmptyState(
            Icons.Rounded.Check, "All done",
            if (kept == 0) "Nothing marked to delete." else "You kept all ${formatCount(kept, "screenshot")}. Nothing to delete.",
            Modifier.fillMaxSize(),
            bottomPadding = 40.dp,
        ) { PillButton("Done", onDone, expand = false) }
        return
    }
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState())
            .padding(start = Insets.page + 2.dp, top = 20.dp, end = Insets.page).entrance(fromY = 16.dp, durationMs = 350),
    ) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { FannedStack(marked.reversed(), 82.dp, 12f) }
        Spacer(Modifier.height(28.dp))
        Text(accented("${marked.size}", "marked.", 44f, Brand.coral), Type.display.copy(fontSize = 44.sp, lineHeight = 50.sp))
        Spacer(Modifier.height(8.dp))
        Text(
            "${formatBytes(marked.sumOf { it.size })} to free" + if (kept > 0) " · you kept ${formatCount(kept, "screenshot")}" else "",
            Type.bodyLarge, color = t.muted,
        )
        Spacer(Modifier.height(28.dp))
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PillButton("Delete ${formatCount(marked.size, "screenshot")}", onDelete, icon = Icons.Rounded.Delete, style = PillStyle.Danger)
            PillButton("Review first", onReview, style = PillStyle.Soft)
            PillButton("Keep going", if (canContinue) onContinue else null, style = PillStyle.Soft)
        }
    }
}

@Composable
private fun SwipeCard(
    shot: Shot,
    width: Dp,
    height: Dp,
    offset: Offset,
    threshold: Float,
    verticalThreshold: Float,
    modifier: Modifier,
    dim: Float = 0f,
) {
    val t = tokens
    val up = offset.y < 0 && abs(offset.y) > abs(offset.x)
    val keep = if (up) 0f else (offset.x / threshold).coerceIn(0f, 1f)
    val delete = if (up) 0f else (-offset.x / threshold).coerceIn(0f, 1f)
    val favorite = if (up) (-offset.y / verticalThreshold).coerceIn(0f, 1f) else 0f
    val shape = RoundedCornerShape(32.dp)
    Box(
        modifier.size(width, height).floating(shape, t, blur = 30.dp, y = 14.dp)
            .background(t.card, shape).padding(6.dp),
    ) {
        Box(Modifier.fillMaxSize().clip(RoundedCornerShape(27.dp))) {
            ShotImage(shot, Modifier.fillMaxSize(), Thumbs.LARGE)
            if (dim > 0) Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = dim)))
            Row(Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f, fill = false)) { GlassTag(shot.app, colorFor(shot.app), Modifier) }
                Spacer(Modifier.width(8.dp))
                Box { GlassTag(shortDate(shot.date), null, Modifier) }
            }
            Stamp("Keep", Icons.Rounded.Check, Brand.mint, -11.5f, keep, Modifier.align(Alignment.TopStart).padding(start = 18.dp, top = 22.dp))
            Stamp("Delete", Icons.Rounded.Close, Brand.coral, 11.5f, delete, Modifier.align(Alignment.TopEnd).padding(end = 18.dp, top = 22.dp))
            Stamp("Favorite", Icons.Rounded.Favorite, t.highlight, 0f, favorite, Modifier.align(Alignment.BottomCenter).padding(bottom = height * 0.32f))
        }
    }
}

@Composable
private fun Stamp(label: String, icon: ImageVector, color: Color, angle: Float, amount: Float, modifier: Modifier) {
    if (amount <= 0f) return
    val shape = RoundedCornerShape(50)
    Row(
        modifier
            .graphicsLayer {
                alpha = amount
                rotationZ = angle
                scaleX = 0.85f + 0.15f * amount
                scaleY = 0.85f + 0.15f * amount
            }
            .background(color, shape).border(3.dp, Color.White, shape)
            .padding(horizontal = 16.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, Color.White, size = 22.dp)
        Spacer(Modifier.width(8.dp))
        Text(label.uppercase(), Type.label.copy(fontSize = 16.sp, letterSpacing = 1.6.sp), color = Color.White, maxLines = 1)
    }
}

@Composable
private fun RoundAction(icon: ImageVector, label: String, size: Dp, background: Color, foreground: Color, onClick: (() -> Unit)?) {
    Box(
        Modifier.size(size).semantics { contentDescription = label }.pressable(onClick, scale = 0.88f)
            .raised(CircleShape, tokens).background(background, CircleShape),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, foreground, size = size * 0.44f) }
}

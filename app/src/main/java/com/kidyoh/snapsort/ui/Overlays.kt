package com.kidyoh.snapsort.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.clickable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** One open bottom sheet, waiting for an answer. */
class SheetScope<T> internal constructor(private val result: CompletableDeferred<T?>, val content: @Composable SheetScope<T>.() -> Unit) {
    /** Closes the sheet with [value] (null means dismissed). */
    fun done(value: T?) {
        result.complete(value)
    }

    internal val finished get() = result.isCompleted
    internal fun dismiss() = result.complete(null)
}

/** Shows bottom sheets one at a time and hands back what was picked. */
@Stable
class Sheets {
    internal var current by mutableStateOf<SheetScope<*>?>(null)

    suspend fun <T> show(content: @Composable SheetScope<T>.() -> Unit): T? {
        current?.dismiss()
        val result = CompletableDeferred<T?>()
        val scope = SheetScope(result, content)
        current = scope
        return try {
            result.await()
        } finally {
            if (current === scope) current = null
        }
    }
}

/** Short confirmations above the nav bar. */
@Stable
class Snacks {
    internal var message by mutableStateOf<Pair<String, ImageVector>?>(null)
    internal var serial by mutableStateOf(0)

    fun show(text: String, icon: ImageVector = Icons.Rounded.CheckCircle) {
        message = text to icon
        serial++
    }
}

@Composable
fun SheetHost(sheets: Sheets) {
    val t = tokens
    val req = sheets.current
    // Keeps the last sheet on screen while it slides away.
    val last = remember { arrayOfNulls<SheetScope<*>>(1) }
    if (req != null) last[0] = req
    BackHandler(enabled = req != null) { req?.dismiss() }

    Box(Modifier.fillMaxSize()) {
        AnimatedVisibility(req != null, enter = fadeIn(tween(220)), exit = fadeOut(tween(220))) {
            Box(
                Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.42f))
                    .clickable(remember { MutableInteractionSource() }, null) { req?.dismiss() },
            )
        }
        AnimatedVisibility(
            req != null,
            modifier = Modifier.align(Alignment.BottomCenter),
            enter = slideInVertically(tween(340, easing = FastOutSlowInEasing)) { it },
            exit = slideOutVertically(tween(260)) { it },
        ) {
            val sheet = last[0] ?: return@AnimatedVisibility
            val drag = remember(sheet) { Animatable(0f) }
            val scope = rememberCoroutineScope()
            val density = LocalDensity.current
            val maxHeight = LocalConfiguration.current.screenHeightDp.dp * 0.92f
            Column(
                Modifier
                    .fillMaxWidth()
                    .windowInsetsPadding(WindowInsets.statusBars)
                    .heightIn(max = maxHeight)
                    .graphicsLayer { translationY = drag.value }
                    .background(t.card, RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp))
                    .clickable(remember { MutableInteractionSource() }, null) {}
                    .windowInsetsPadding(WindowInsets.navigationBars)
                    .imePadding(),
            ) {
                // Drag handle: pull down to close.
                Box(
                    Modifier.fillMaxWidth().height(36.dp).draggable(
                        rememberDraggableState { d -> scope.launch { drag.snapTo((drag.value + d).coerceAtLeast(0f)) } },
                        Orientation.Vertical,
                        onDragStopped = { v ->
                            if (drag.value > with(density) { 110.dp.toPx() } || v > 1500f) sheet.dismiss()
                            else drag.animateTo(0f)
                        },
                    ),
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.size(36.dp, 4.dp).background(t.border, RoundedCornerShape(50)))
                }
                Column(Modifier.padding(start = 24.dp, end = 24.dp, bottom = 20.dp)) {
                    @Suppress("UNCHECKED_CAST")
                    (sheet as SheetScope<Any?>).content(sheet)
                }
            }
        }
    }
}

@Composable
fun BoxScope.SnackHost(snacks: Snacks) {
    val msg = snacks.message
    val serial = snacks.serial
    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(serial) {
        if (msg == null) return@LaunchedEffect
        visible = true
        delay(3200)
        visible = false
    }
    AnimatedVisibility(
        visible,
        modifier = Modifier.align(Alignment.BottomCenter).windowInsetsPadding(WindowInsets.navigationBars)
            .padding(start = 20.dp, end = 20.dp, bottom = 104.dp),
        enter = fadeIn(tween(200)) + slideInVertically(tween(260)) { it / 2 },
        exit = fadeOut(tween(200)),
    ) {
        val (text, icon) = msg ?: return@AnimatedVisibility
        Row(
            Modifier.fillMaxWidth().background(tokens.navBar, RoundedCornerShape(18.dp)).padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(icon, Color.White, size = 20.dp)
            Spacer(Modifier.width(12.dp))
            Text(text, Type.body, color = Color.White)
        }
    }
}

/** Sheet heading: big title with an optional serif accent and a message. */
@Composable
fun SheetHeading(title: String, accent: String? = null, message: String? = null) {
    PageTitle(lead = title, accent = accent, size = 28f)
    if (message != null) {
        Spacer(Modifier.height(8.dp))
        Text(message, Type.body, color = tokens.muted)
    }
    Spacer(Modifier.height(20.dp))
}

/** Two stacked pill buttons: the action and a soft "Cancel" style one. */
@Composable
fun ColumnScope.SheetButtons(action: String, onAction: () -> Unit, other: String, onOther: () -> Unit, style: PillStyle = PillStyle.Primary) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        PillButton(action, onAction, style = style)
        PillButton(other, onOther, style = PillStyle.Soft)
    }
}

package com.kidyoh.snapsort.ui

import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.Image
import androidx.compose.ui.graphics.ColorFilter

// ---- Small helpers ----

/** Haptic ticks, through the view so they follow the phone's settings. */
class Haptics(private val view: View) {
    fun tick() = view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
    fun light() = view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
    fun medium() = view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
}

@Composable
fun rememberHaptics(): Haptics {
    val view = LocalView.current
    return remember(view) { Haptics(view) }
}

/** Springy press feedback: shrinks a little under the finger, bounces back. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun Modifier.pressable(
    onClick: (() -> Unit)?,
    onLongClick: (() -> Unit)? = null,
    scale: Float = 0.96f,
    label: String? = null,
): Modifier {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val s by animateFloatAsState(
        if (pressed) scale else 1f,
        if (pressed) tween(110) else spring(dampingRatio = 0.42f, stiffness = Spring.StiffnessMediumLow),
        label = "press",
    )
    val enabled = onClick != null || onLongClick != null
    return this
        .graphicsLayer { scaleX = s; scaleY = s }
        .combinedClickable(
            interactionSource = source,
            indication = null,
            enabled = enabled,
            role = Role.Button,
            onClickLabel = label,
            onLongClick = onLongClick,
            onClick = onClick ?: {},
        )
}

/** The soft floating shadow from the design (none in dark mode). */
fun Modifier.raised(shape: Shape, t: Tokens, alpha: Float = 0.08f, blur: Dp = 28.dp, y: Dp = 12.dp): Modifier =
    if (!t.raised) this else dropShadow(shape, Shadow(radius = blur, color = Color.Black.copy(alpha = alpha), offset = DpOffset(0.dp, y)))

/** A deeper shadow for things that float over content. */
fun Modifier.floating(shape: Shape, t: Tokens, blur: Dp = 30.dp, y: Dp = 12.dp): Modifier =
    dropShadow(shape, Shadow(radius = blur, color = Color.Black.copy(alpha = if (t.dark) 0.5f else 0.22f), offset = DpOffset(0.dp, y)))

/** Fades and slides in once when first shown. */
@Composable
fun Modifier.entrance(delayMs: Int = 0, fromY: Dp = 18.dp, durationMs: Int = 500, fromX: Dp = 0.dp): Modifier {
    val p = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        p.animateTo(1f, tween(durationMs, delayMs, FastOutSlowInEasing))
    }
    return graphicsLayer {
        alpha = p.value
        translationY = (1 - p.value) * fromY.toPx()
        translationX = (1 - p.value) * fromX.toPx()
    }
}

@Composable
fun Icon(icon: ImageVector, tint: Color, modifier: Modifier = Modifier, size: Dp = 24.dp) {
    Image(icon, null, modifier.size(size), colorFilter = ColorFilter.tint(tint))
}

@Composable
fun Text(
    text: String,
    style: TextStyle,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    maxLines: Int = Int.MAX_VALUE,
    align: TextAlign? = null,
) {
    val t = tokens
    BasicText(
        text,
        modifier,
        style = style.merge(
            TextStyle(
                color = if (color != Color.Unspecified) color else if (style.color != Color.Unspecified) style.color else t.ink,
                textAlign = align ?: TextAlign.Unspecified,
            ),
        ),
        maxLines = maxLines,
        overflow = if (maxLines == Int.MAX_VALUE) TextOverflow.Clip else TextOverflow.Ellipsis,
    )
}

@Composable
fun Text(
    text: AnnotatedString,
    style: TextStyle,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    maxLines: Int = Int.MAX_VALUE,
) {
    val t = tokens
    BasicText(
        text,
        modifier,
        style = style.merge(TextStyle(color = if (color != Color.Unspecified) color else t.ink)),
        maxLines = maxLines,
        overflow = if (maxLines == Int.MAX_VALUE) TextOverflow.Clip else TextOverflow.Ellipsis,
    )
}

/** Lead words in the sans, then the accent in the serif italic. */
fun accented(lead: String, accent: String?, size: Float, color: Color): AnnotatedString = buildAnnotatedString {
    append(lead)
    if (accent != null) {
        append(" ")
        val s = serif(size, color)
        withStyle(SpanStyle(fontFamily = s.fontFamily, fontStyle = s.fontStyle, fontWeight = FontWeight.Normal, fontSize = s.fontSize, letterSpacing = s.letterSpacing, color = color)) {
            append(accent)
        }
    }
}

@Composable
fun Dot(color: Color, size: Dp = 8.dp) {
    Box(Modifier.size(size).background(color, CircleShape))
}

// ---- Buttons ----

/** White (or dark) circular icon button, used in headers. */
@Composable
fun CircleButton(icon: ImageVector, label: String, onClick: (() -> Unit)?, size: Dp = 46.dp, filled: Boolean = false) {
    val t = tokens
    Box(
        Modifier
            .size(size)
            .semantics { contentDescription = label }
            .pressable(onClick, scale = 0.9f)
            .raised(CircleShape, t)
            .background(if (filled) t.ink else t.card, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, if (filled) t.canvas else t.ink, size = size * 0.46f)
    }
}

enum class PillStyle { Primary, Ink, Soft, Danger }

/** Stadium button: violet for the main action, card-coloured for others. */
@Composable
fun PillButton(
    label: String,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: PillStyle = PillStyle.Primary,
    busy: Boolean = false,
    height: Dp = 56.dp,
    expand: Boolean = true,
) {
    val t = tokens
    val (bg, fg) = when (style) {
        PillStyle.Primary -> t.highlight to Color.White
        PillStyle.Ink -> t.ink to t.canvas
        PillStyle.Soft -> t.track to t.ink
        PillStyle.Danger -> Brand.coral to Color.White
    }
    Row(
        modifier
            .then(if (expand) Modifier.fillMaxWidth() else Modifier)
            .height(height)
            .pressable(if (busy) null else onClick)
            .alpha(if (onClick == null && !busy) 0.45f else 1f)
            .background(bg, RoundedCornerShape(50))
            .padding(horizontal = height * 0.42f),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (busy) {
            Spinner(fg, Modifier.size(18.dp), 2.2.dp)
        } else {
            if (icon != null) {
                Icon(icon, fg, size = height * 0.36f)
                Spacer(Modifier.width(height * 0.15f))
            }
            Text(
                label,
                Type.label.copy(fontSize = if (height >= 50.dp) 15.sp else 13.5.sp),
                color = fg,
                maxLines = 1,
            )
        }
    }
}

// ---- Text blocks ----

/** Small spaced capitals above a section. */
@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier, trailing: String? = null) {
    val t = tokens
    Text(
        buildAnnotatedString {
            append(text.uppercase())
            if (trailing != null) withStyle(SpanStyle(color = t.faint)) { append("   $trailing") }
        },
        Type.overline,
        modifier,
        color = t.muted,
        maxLines = 1,
    )
}

/** Big screen title, with the last word set in the serif italic accent. */
@Composable
fun PageTitle(lead: String, accent: String? = null, overline: String? = null, size: Float = 38f, modifier: Modifier = Modifier) {
    val t = tokens
    Column(modifier) {
        if (overline != null) {
            Text(overline, Type.body.copy(fontWeight = FontWeight.SemiBold), color = t.muted)
            Spacer(Modifier.height(4.dp))
        }
        Text(
            accented(lead, accent, size, t.highlight),
            Type.display.copy(fontSize = size.sp, lineHeight = (size * 1.1f).sp),
            maxLines = 2,
        )
    }
}

// ---- Surfaces ----

/** The rounded card everything sits on. */
@Composable
fun Panel(
    modifier: Modifier = Modifier,
    padding: PaddingValues = PaddingValues(18.dp),
    color: Color? = null,
    radius: Dp = Insets.radius,
    onClick: (() -> Unit)? = null,
    onLongClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(radius)
    Column(
        modifier
            .fillMaxWidth()
            .then(if (onClick != null || onLongClick != null) Modifier.pressable(onClick, onLongClick, 0.98f) else Modifier)
            .clip(shape)
            .background(color ?: tokens.card)
            .padding(padding),
        content = content,
    )
}

/** A rounded square with a tinted icon. */
@Composable
fun IconBadge(icon: ImageVector, color: Color, size: Dp = 44.dp) {
    Box(
        Modifier.size(size).background(tokens.wash(color, 1.2f), RoundedCornerShape(size * 0.34f)),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, color, size = size * 0.5f) }
}

/** Frosted panel for controls that float over screenshots. */
@Composable
fun Glass(
    modifier: Modifier = Modifier,
    radius: Dp = 20.dp,
    padding: PaddingValues = PaddingValues(0.dp),
    content: @Composable RowScope.() -> Unit,
) {
    val shape = RoundedCornerShape(radius)
    Row(
        modifier
            .clip(shape)
            .background(Color.Black.copy(alpha = 0.52f))
            .border(1.dp, Color.White.copy(alpha = 0.14f), shape)
            .padding(padding),
        verticalAlignment = Alignment.CenterVertically,
        content = content,
    )
}

@Composable
fun GlassButton(icon: ImageVector, label: String, onClick: () -> Unit, size: Dp = 46.dp) {
    Glass(
        Modifier.size(size).semantics { contentDescription = label }.pressable(onClick, scale = 0.9f),
        radius = size / 2,
    ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { Icon(icon, Color.White, size = 22.dp) }
    }
}

// ---- Choosers ----

/** Horizontally scrolling filter pills; the selected one is filled. */
@Composable
fun <T> PillFilters(options: List<Triple<T?, String, Int?>>, selected: T?, onChange: (T?) -> Unit) {
    val t = tokens
    val haptics = rememberHaptics()
    Row(
        Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = Insets.page),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        for ((value, label, count) in options) {
            val on = value == selected
            val bg by animateColorAsState(if (on) t.ink else t.card, tween(220), label = "pill")
            Box(
                Modifier
                    .pressable({ haptics.tick(); onChange(value) })
                    .background(bg, RoundedCornerShape(50))
                    .padding(horizontal = 16.dp, vertical = 10.dp),
            ) {
                Text(
                    buildAnnotatedString {
                        append(label)
                        if (count != null) withStyle(SpanStyle(color = t.faint, fontWeight = FontWeight.SemiBold)) { append("  $count") }
                    },
                    Type.label,
                    color = if (on) t.canvas else t.ink,
                    maxLines = 1,
                )
            }
        }
    }
}

/** Segmented pill control with a sliding thumb. */
@Composable
fun <T> PillTabs(
    values: List<T>,
    label: (T) -> String,
    selected: T,
    onChange: (T) -> Unit,
    height: Dp = 46.dp,
) {
    val t = tokens
    val haptics = rememberHaptics()
    BoxWithConstraints(
        Modifier.fillMaxWidth().height(height).background(t.track, RoundedCornerShape(50)).padding(4.dp),
    ) {
        val w = maxWidth / values.size
        val x by animateDpAsState(w * values.indexOf(selected), tween(280, easing = FastOutSlowInEasing), label = "thumb")
        Box(
            Modifier.offset(x = x).width(w).fillMaxHeight()
                .raised(RoundedCornerShape(50), t)
                .background(t.card, RoundedCornerShape(50)),
        )
        Row(Modifier.fillMaxSize()) {
            for (v in values) {
                val color by animateColorAsState(if (v == selected) t.ink else t.muted, tween(200), label = "tab")
                Box(
                    Modifier.weight(1f).fillMaxHeight()
                        .combinedClickable(
                            interactionSource = null,
                            indication = null,
                            role = Role.Tab,
                            onClick = { if (v != selected) { haptics.tick(); onChange(v) } },
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(label(v), Type.label.copy(fontSize = 13.5.sp), color = color, maxLines = 1)
                }
            }
        }
    }
}

// ---- Feedback ----

@Composable
fun Spinner(color: Color, modifier: Modifier = Modifier.size(28.dp), stroke: Dp = 3.dp) {
    val transition = rememberInfiniteTransition(label = "spin")
    val angle by transition.animateFloat(0f, 360f, infiniteRepeatable(tween(900, easing = LinearEasing)), label = "angle")
    val sweep by transition.animateFloat(40f, 260f, infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "sweep")
    Canvas(modifier) {
        drawArc(color, angle, sweep, false, style = Stroke(stroke.toPx(), cap = StrokeCap.Round))
    }
}

@Composable
fun ProgressBar(progress: Float, modifier: Modifier = Modifier, color: Color = tokens.highlight, track: Color = tokens.track, height: Dp = 8.dp) {
    val p by animateFloatAsState(progress.coerceIn(0f, 1f), tween(250), label = "progress")
    Box(modifier.fillMaxWidth().height(height).clip(RoundedCornerShape(50)).background(track)) {
        Box(Modifier.fillMaxWidth(p).fillMaxHeight().background(color, RoundedCornerShape(50)))
    }
}

/** A rounded bar split into coloured parts: (fraction, colour) pairs. */
@Composable
fun SegmentBar(parts: List<Pair<Float, Color>>, height: Dp = 12.dp, track: Color = tokens.track) {
    Row(Modifier.fillMaxWidth().height(height).clip(RoundedCornerShape(50)).background(track)) {
        val shown = parts.filter { it.first > 0 }
        shown.forEachIndexed { i, (f, c) ->
            Box(
                Modifier.weight(f.coerceAtLeast(0.001f)).fillMaxHeight()
                    .padding(end = if (i == shown.lastIndex) 0.dp else 2.dp)
                    .background(c),
            )
        }
        val rest = 1f - shown.sumOf { it.first.toDouble() }.toFloat()
        if (rest > 0.001f) Spacer(Modifier.weight(rest))
    }
}

/** Counts up to [value] whenever it changes. */
@Composable
fun CountUp(value: Float, format: (Float) -> String, style: TextStyle, color: Color) {
    val v = remember { Animatable(0f) }
    LaunchedEffect(value) { v.animateTo(value, tween(900, easing = FastOutSlowInEasing)) }
    Text(format(v.value), style, color = color, maxLines = 1)
}

/** Friendly empty screen with an orbiting-icon illustration. */
@Composable
fun EmptyState(
    icon: ImageVector,
    title: String,
    message: String,
    modifier: Modifier = Modifier,
    bottomPadding: Dp = Insets.navClearance,
    action: (@Composable () -> Unit)? = null,
) {
    val t = tokens
    val pop = remember { Animatable(0.85f) }
    LaunchedEffect(Unit) { pop.animateTo(1f, spring(dampingRatio = 0.5f, stiffness = Spring.StiffnessLow)) }
    @Composable
    fun orbit(i: ImageVector, c: Color, m: Modifier) {
        Box(
            m.size(38.dp).background(t.card, CircleShape).border(1.5.dp, t.ink, CircleShape),
            contentAlignment = Alignment.Center,
        ) { Icon(i, c, size = 18.dp) }
    }
    Box(modifier.fillMaxWidth().padding(start = 36.dp, top = 24.dp, end = 36.dp, bottom = bottomPadding), contentAlignment = Alignment.Center) {
        Column(Modifier.entrance(fromY = 0.dp, durationMs = 400), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.size(150.dp, 130.dp).scale(pop.value), contentAlignment = Alignment.Center) {
                Box(Modifier.size(108.dp).background(t.highlight, CircleShape), contentAlignment = Alignment.Center) {
                    Icon(icon, Color.White, size = 44.dp)
                }
                orbit(Icons.Rounded.AutoAwesome, Brand.amber, Modifier.align(Alignment.TopStart).offset(y = 10.dp))
                orbit(Icons.Rounded.Favorite, Brand.coral, Modifier.align(Alignment.BottomEnd).offset(x = (-2).dp, y = (-6).dp))
            }
            Spacer(Modifier.height(22.dp))
            Text(title, Type.headline, align = TextAlign.Center)
            Spacer(Modifier.height(8.dp))
            Text(message, Type.body, color = t.muted, align = TextAlign.Center)
            if (action != null) {
                Spacer(Modifier.height(24.dp))
                action()
            }
        }
    }
}

/** Centered loading spinner that fills the space it's given. */
@Composable
fun Loading(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().heightIn(min = 240.dp), contentAlignment = Alignment.Center) {
        Spinner(tokens.highlight)
    }
}


package com.kidyoh.snapsort.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ImageNotSupported
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.data.Section
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.Thumbs
import com.kidyoh.snapsort.data.shortDate

/** Loads [shot] at [width] pixels; shows the smaller cached copy meanwhile. */
@Composable
fun rememberShotImage(shot: Shot, width: Int): ImageBitmap? {
    val thumbs = LocalApp.current.thumbs
    var image by remember(shot.id, width) {
        mutableStateOf(thumbs.cached(shot.id, width) ?: if (width > Thumbs.THUMB) thumbs.cached(shot.id, Thumbs.THUMB) else null)
    }
    LaunchedEffect(shot.id, width) {
        if (thumbs.cached(shot.id, width) == null) {
            thumbs.load(shot.id, width)?.let { image = it }
        }
    }
    return image
}

/** A screenshot that fades in once decoded, on a placeholder tint. */
@Composable
fun ShotImage(
    shot: Shot,
    modifier: Modifier = Modifier,
    width: Int = Thumbs.THUMB,
    scale: ContentScale = ContentScale.Crop,
) {
    val t = tokens
    val image = rememberShotImage(shot, width)
    val alpha by animateFloatAsState(if (image != null) 1f else 0f, tween(300), label = "fade")
    Box(modifier.background(t.track)) {
        if (image != null) {
            Image(
                image, null,
                Modifier.fillMaxSize().graphicsLayer { this.alpha = alpha },
                contentScale = scale,
                alignment = Alignment.TopCenter,
            )
        }
    }
}

/** Rounded thumbnail with a hairline edge. */
@Composable
fun RoundedShot(shot: Shot, modifier: Modifier = Modifier, radius: Dp = Insets.tile, width: Int = Thumbs.THUMB) {
    val shape = RoundedCornerShape(radius)
    val edge = (if (tokens.dark) Color.White else Color.Black).copy(alpha = 0.07f)
    ShotImage(shot, modifier.clip(shape).border(1.dp, edge, shape), width)
}

/** Which screenshots are ticked. */
class Selection(initial: Set<Long> = emptySet()) {
    var ids by mutableStateOf(initial)
        private set

    val active get() = ids.isNotEmpty()
    operator fun contains(s: Shot) = s.id in ids
    fun toggle(s: Shot) {
        ids = if (s.id in ids) ids - s.id else ids + s.id
    }

    fun setAll(shots: List<Shot>, selected: Boolean) {
        ids = if (selected) ids + shots.map { it.id } else ids - shots.map { it.id }.toSet()
    }

    fun clear() {
        ids = emptySet()
    }
}

/** A grid cell: tap to open, long-press to start selecting. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ShotTile(shot: Shot, selection: Selection, favorite: Boolean, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val t = tokens
    val haptics = rememberHaptics()
    val selecting = selection.active
    val selected = shot in selection
    val inset by animateDpAsState(if (selected) 7.dp else 0.dp, tween(180), label = "inset")
    val radius by animateDpAsState(if (selected) 10.dp else Insets.tile, tween(180), label = "radius")
    Box(
        modifier
            .semantics {
                contentDescription = "${shot.app} screenshot, ${shortDate(shot.date)}"
                this.selected = selected
            }
            .combinedClickable(
                interactionSource = null,
                indication = null,
                onLongClick = { haptics.medium(); selection.toggle(shot) },
                onClick = {
                    if (selecting) {
                        haptics.tick()
                        selection.toggle(shot)
                    } else onOpen()
                },
            ),
    ) {
        RoundedShot(shot, Modifier.fillMaxSize().padding(inset), radius)
        if (favorite) {
            Box(
                Modifier.align(Alignment.BottomStart).offset(x = 6.dp + inset, y = -(6.dp + inset)).size(22.dp)
                    .background(Brand.coral, CircleShape).border(1.5.dp, Color.White, CircleShape),
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Rounded.Favorite, Color.White, size = 12.dp) }
        }
        if (selecting) {
            val fill by animateColorAsState(if (selected) t.highlight else Color.Black.copy(alpha = 0.18f), tween(180), label = "tick")
            Box(
                Modifier.align(Alignment.TopEnd).padding(6.dp).size(24.dp)
                    .background(fill, CircleShape).border(2.dp, Color.White, CircleShape),
                contentAlignment = Alignment.Center,
            ) { if (selected) Icon(Icons.Rounded.Check, Color.White, size = 15.dp) }
        }
    }
}

/** Up to three screenshots fanned out like a hand of cards (the app icon's motif). */
@Composable
fun FannedStack(shots: List<Shot>, cardWidth: Dp = 58.dp, spread: Float = 11f) {
    val t = tokens
    val cards = shots.take(3).reversed()
    val h = cardWidth * 2.05f
    val angles = listOf(-1f, 1f, 0f)
    Box(Modifier.size(cardWidth * 2.2f, h + 12.dp), contentAlignment = Alignment.Center) {
        if (cards.isEmpty()) {
            Box(Modifier.size(cardWidth, h).background(t.card.copy(alpha = 0.7f), RoundedCornerShape(cardWidth * 0.16f)))
        }
        cards.forEachIndexed { i, s ->
            val a = if (cards.size == 1) 0f else angles[i + 3 - cards.size]
            val shape = RoundedCornerShape(cardWidth * 0.16f)
            Box(
                Modifier
                    .offset(x = cardWidth * 0.42f * a)
                    .rotate(a * spread)
                    .size(cardWidth, h)
                    .floating(shape, t, blur = 14.dp, y = 6.dp)
                    .background(t.card, shape)
                    .padding(2.5.dp),
            ) {
                RoundedShot(s, Modifier.fillMaxSize(), cardWidth * 0.13f)
            }
        }
    }
}

/** Grid section header: label + count, with "Select all" while selecting. */
@Composable
fun SectionHeader(section: Section, selection: Selection) {
    val selecting = selection.active
    val all = selecting && section.shots.all { it in selection }
    Row(
        Modifier.padding(start = Insets.page + 2.dp, top = 26.dp, end = Insets.page - 6.dp, bottom = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SectionLabel(section.title, Modifier.weight(1f), trailing = section.subtitle ?: "${section.shots.size}")
        val alpha by animateFloatAsState(if (selecting) 1f else 0f, tween(180), label = "selectAll")
        Text(
            if (all) "Deselect" else "Select all",
            Type.labelMedium,
            Modifier
                .graphicsLayer { this.alpha = alpha }
                .combinedClickable(interactionSource = null, indication = null, enabled = selecting) {
                    selection.setAll(section.shots, !all)
                }
                .padding(horizontal = 6.dp, vertical = 2.dp),
            color = tokens.highlight,
        )
    }
}

/** A dark-tinted label pill for use over screenshots. */
@Composable
fun BoxScope.GlassTag(text: String, dot: Color?, modifier: Modifier) {
    Glass(modifier, radius = 14.dp, padding = androidx.compose.foundation.layout.PaddingValues(horizontal = 10.dp, vertical = 6.dp)) {
        if (dot != null) {
            Dot(dot, 7.dp)
            androidx.compose.foundation.layout.Spacer(Modifier.size(6.dp))
        }
        Text(text, Type.labelMedium, color = Color.White, maxLines = 1)
    }
}

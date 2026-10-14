package com.kidyoh.snapsort.ui.screens

import androidx.annotation.DrawableRes
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Easing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.PhotoLibrary
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.R
import com.kidyoh.snapsort.data.PhotoAccess
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.Dot
import com.kidyoh.snapsort.ui.Icon
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.PageTitle
import com.kidyoh.snapsort.ui.PillButton
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.colorFor
import com.kidyoh.snapsort.ui.floating
import com.kidyoh.snapsort.ui.raised
import com.kidyoh.snapsort.ui.rememberHaptics
import com.kidyoh.snapsort.ui.serif
import com.kidyoh.snapsort.ui.tokens
import kotlinx.coroutines.launch

private class Page(val lead: String, val accent: String, val body: String, val art: @Composable (Boolean) -> Unit)

private val pages = listOf(
    Page("Screenshots,", "sorted.", "SnapSort reads your Screenshots folder and tidies it up for you. No AI, no account.") { FanArt(it) },
    Page("Grouped by", "app.", "WhatsApp chats, receipts, maps and memes each get their own pile, straight from the file names.") { SortArt(it) },
    Page("Clear the", "clutter.", "Find exact duplicates, old screenshots and the biggest files, and free up space in a tap.") { CleanArt(it) },
)

/** First-run walkthrough that ends by asking for photo access. */
@Composable
fun OnboardingScreen() {
    val lib = LocalApp.current.lib
    val t = tokens
    val haptics = rememberHaptics()
    val scope = rememberCoroutineScope()
    val pager = rememberPagerState { pages.size }
    var asking by remember { mutableStateOf(false) }
    val last = pager.currentPage == pages.lastIndex
    val denied = lib.access == PhotoAccess.Denied
    LaunchedEffect(pager.currentPage) { if (pager.currentPage > 0) haptics.tick() }

    Column(Modifier.fillMaxSize().background(t.canvas)) {
        HorizontalPager(pager, Modifier.weight(1f)) { i ->
            val p = pages[i]
            Column(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.statusBars).padding(start = 28.dp, top = 24.dp, end = 28.dp)) {
                Text("snapsort", serif(24f, t.ink))
                Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) { p.art(i == pager.currentPage) }
                PageTitle(p.lead, p.accent, size = 44f)
                Spacer(Modifier.height(14.dp))
                Text(p.body, Type.bodyLarge, color = t.muted)
            }
        }
        Column(
            Modifier.windowInsetsPadding(WindowInsets.navigationBars).padding(start = 28.dp, top = 22.dp, end = 28.dp, bottom = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (last && denied) {
                Text(
                    "Photo access is off. SnapSort needs it to see your screenshots.",
                    Type.body, Modifier.padding(bottom = 14.dp), color = Brand.coral, align = TextAlign.Center,
                )
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                for (i in pages.indices) {
                    val on = i == pager.currentPage
                    val w by animateDpAsState(if (on) 26.dp else 8.dp, tween(300, easing = FastOutSlowInEasing), label = "dot")
                    val c by animateColorAsState(if (on) t.ink else t.border, tween(300), label = "dotColor")
                    Box(Modifier.padding(end = 6.dp).size(w, 8.dp).background(c, RoundedCornerShape(4.dp)))
                }
                Spacer(Modifier.weight(1f))
                PillButton(
                    if (last) (if (denied) "Try again" else "Allow access") else "Next",
                    {
                        if (!last) scope.launch { pager.animateScrollToPage(pager.currentPage + 1, animationSpec = tween(650, easing = FastOutSlowInEasing)) }
                        else {
                            asking = true
                            scope.launch {
                                lib.askForAccess().join()
                                asking = false
                            }
                        }
                    },
                    icon = if (last) Icons.Rounded.PhotoLibrary else Icons.AutoMirrored.Rounded.ArrowForward,
                    expand = false,
                    busy = asking,
                )
            }
            if (last && denied) {
                Text(
                    "Open Settings", Type.label,
                    Modifier.padding(top = 10.dp).combinedClickable(interactionSource = null, indication = null) { lib.openAppSettings() }
                        .padding(8.dp),
                    color = t.highlight,
                )
            }
        }
    }
}

// ---- Art ----

/** Flutter's easeOutBack: overshoots a little, then settles. */
private val EaseOutBack: Easing = CubicBezierEasing(0.175f, 0.885f, 0.32f, 1.275f)

@Composable
private fun progress(active: Boolean, durationMs: Int = 1300, easing: Easing = EaseOutBack): Float {
    val p by animateFloatAsState(if (active) 1f else 0f, tween(durationMs, easing = easing), label = "art")
    return p
}

/** A screenshot card used in the onboarding art. */
@Composable
private fun Card(@DrawableRes image: Int, width: Dp, modifier: Modifier = Modifier) {
    val t = tokens
    val shape = RoundedCornerShape(width * 0.13f)
    Box(
        modifier.size(width, width * 2.1f)
            .floating(shape, t.copy(dark = false), blur = 24.dp, y = 12.dp)
            .background(t.card, shape).padding(3.dp)
            .clip(RoundedCornerShape(width * 0.11f)),
    ) {
        Image(painterResource(image), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop, alignment = Alignment.TopCenter)
    }
}

/** A messy pile of screenshots fanning out. */
@Composable
private fun FanArt(active: Boolean) {
    val t = progress(active)
    val images = listOf(R.drawable.demo_maps, R.drawable.demo_spotify, R.drawable.demo_whatsapp, R.drawable.demo_instagram, R.drawable.demo_chrome)
    val angles = listOf(-18f, -9f, 0f, 9f, 18f)
    Box(contentAlignment = Alignment.Center) {
        Box(Modifier.size(240.dp).background(Brand.violet.copy(alpha = if (tokens.dark) 0.16f else 0.10f), CircleShape))
        images.forEachIndexed { i, img ->
            Card(
                img, 108.dp,
                Modifier
                    .offset(x = ((i - 2) * 16f * t).dp, y = (kotlin.math.abs(i - 2) * 8f * t).dp)
                    .graphicsLayer {
                        rotationZ = angles[i] * t
                        transformOrigin = TransformOrigin(0.5f, 1.6f)
                    },
            )
        }
    }
}

/** Screenshots dropping into labelled piles, one per app. */
@Composable
private fun SortArt(active: Boolean) {
    val t = progress(active, 1600, CubicBezierEasing(0f, 0f, 0.58f, 1f))
    val piles = listOf(
        "WhatsApp" to listOf(R.drawable.demo_whatsapp2, R.drawable.demo_whatsapp),
        "Chrome" to listOf(R.drawable.demo_chrome2, R.drawable.demo_chrome),
        "Maps" to listOf(R.drawable.demo_maps, R.drawable.demo_maps),
    )
    fun stagger(i: Int) = EaseOutBack.transform(((t * 1.6f) - i * 0.12f).coerceIn(0f, 1f))
    Row(horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.Bottom) {
        piles.forEachIndexed { i, (name, cards) ->
            Column(Modifier.padding(horizontal = 7.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.size(92.dp, 190.dp), contentAlignment = Alignment.BottomCenter) {
                    cards.forEachIndexed { j, img ->
                        val s = stagger(i * 2 + j)
                        Card(
                            img, 80.dp,
                            Modifier.graphicsLayer {
                                translationY = (-12f * j - (1 - s) * 260f) * density
                                alpha = s.coerceIn(0f, 1f)
                                rotationZ = if (j == 0) -4f else 5f
                            },
                        )
                    }
                }
                Spacer(Modifier.height(16.dp))
                Row(
                    Modifier.graphicsLayer { alpha = t.coerceIn(0f, 1f) }
                        .raised(RoundedCornerShape(50), tokens).background(tokens.card, RoundedCornerShape(50))
                        .padding(horizontal = 12.dp, vertical = 7.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Dot(colorFor(name))
                    Spacer(Modifier.width(6.dp))
                    Text(name, Type.labelMedium, maxLines = 1)
                }
            }
        }
    }
}

/** A duplicate copy flying off into the bin, freeing space. */
@Composable
private fun CleanArt(active: Boolean) {
    val t = progress(active, 1700, LinearEasing)
    val fly = FastOutSlowInEasing.transform((t * 1.3f).coerceIn(0f, 1f))
    val pop = EaseOutBack.transform(((t - 0.6f) / 0.4f).coerceIn(0f, 1f))
    Box(Modifier.size(300.dp, 320.dp), contentAlignment = Alignment.Center) {
        Card(R.drawable.demo_bank, 122.dp, Modifier.offset(x = (-34).dp).graphicsLayer { rotationZ = -6f })
        Card(
            R.drawable.demo_bank, 122.dp,
            Modifier.offset(x = (34 + fly * 70).dp, y = (fly * 120).dp).graphicsLayer {
                rotationZ = 6 + fly * 40
                scaleX = 1 - fly * 0.65f
                scaleY = 1 - fly * 0.65f
                alpha = 1 - fly * 0.8f
            },
        )
        Box(
            Modifier.align(Alignment.BottomEnd).padding(end = 18.dp)
                .graphicsLayer { scaleX = 0.6f + 0.4f * fly; scaleY = 0.6f + 0.4f * fly }
                .size(64.dp).background(Brand.coral, CircleShape),
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Rounded.Delete, Color.White, size = 30.dp) }
        Row(
            Modifier.align(Alignment.TopCenter).padding(top = 6.dp)
                .graphicsLayer { scaleX = pop; scaleY = pop }
                .background(tokens.navBar, RoundedCornerShape(50)).padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Rounded.AutoAwesome, Brand.amber, size = 18.dp)
            Spacer(Modifier.width(8.dp))
            Text("2.4 MB freed", Type.label, color = Color.White, maxLines = 1)
        }
    }
}

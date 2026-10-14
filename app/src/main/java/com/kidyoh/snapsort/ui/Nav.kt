package com.kidyoh.snapsort.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

class NavDestination(val icon: ImageVector, val selectedIcon: ImageVector, val label: String)

private val NavInk = Color(0xFF16151A)

/** Floating dark pill navigation; the current tab grows into a labelled pill. */
@Composable
fun FloatingNav(destinations: List<NavDestination>, selected: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier) {
    val t = tokens
    val haptics = rememberHaptics()
    val shape = RoundedCornerShape(50)
    Row(
        modifier.height(66.dp).floating(shape, t).background(t.navBar, shape).padding(horizontal = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        destinations.forEachIndexed { i, d ->
            val on = i == selected
            val bg by animateColorAsState(if (on) Color.White else Color.Transparent, tween(320), label = "nav")
            val pad by animateDpAsState(if (on) 18.dp else 15.dp, tween(320, easing = FastOutSlowInEasing), label = "navPad")
            Row(
                Modifier
                    .semantics { contentDescription = d.label; this.selected = on }
                    .pressable({ if (!on) haptics.tick(); onSelect(i) }, scale = 0.92f)
                    .height(52.dp)
                    .background(bg, shape)
                    .padding(horizontal = pad),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(if (on) d.selectedIcon else d.icon, if (on) NavInk else Color.White.copy(alpha = 0.62f), size = 23.dp)
                AnimatedVisibility(
                    on,
                    enter = expandHorizontally(tween(320, easing = FastOutSlowInEasing)) + fadeIn(tween(320)),
                    exit = shrinkHorizontally(tween(320, easing = FastOutSlowInEasing)) + fadeOut(tween(160)),
                ) {
                    Row {
                        Spacer(Modifier.width(8.dp))
                        Text(d.label, Type.label, color = NavInk, maxLines = 1)
                    }
                }
            }
        }
    }
}

class DockAction(val icon: ImageVector, val label: String, val danger: Boolean = false, val onClick: () -> Unit)

/** Floating action bar shown while screenshots are selected. */
@Composable
fun SelectionDock(actions: List<DockAction>, modifier: Modifier = Modifier) {
    val t = tokens
    val shape = RoundedCornerShape(28.dp)
    Row(
        modifier.fillMaxWidth().height(70.dp).floating(shape, t).background(t.navBar, shape).padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
    ) {
        for (a in actions) {
            Column(
                Modifier.weight(1f).fillMaxHeight().semantics { contentDescription = a.label }.pressable(a.onClick, scale = 0.9f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Icon(a.icon, if (a.danger) Brand.coral else Color.White, size = 23.dp)
                Spacer(Modifier.height(4.dp))
                Text(
                    a.label,
                    Type.labelMedium.copy(fontSize = 11.5.sp),
                    color = if (a.danger) Brand.coral else Color.White.copy(alpha = 0.8f),
                    maxLines = 1,
                )
            }
        }
    }
}

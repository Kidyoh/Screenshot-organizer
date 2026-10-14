package com.kidyoh.snapsort.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Apps
import androidx.compose.material.icons.outlined.CleaningServices
import androidx.compose.material.icons.outlined.PhotoAlbum
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material.icons.rounded.Apps
import androidx.compose.material.icons.rounded.CleaningServices
import androidx.compose.material.icons.automirrored.rounded.ManageSearch
import androidx.compose.material.icons.rounded.PhotoAlbum
import androidx.compose.material.icons.rounded.PhotoLibrary
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.data.formatCount
import com.kidyoh.snapsort.ui.AppState
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.FloatingNav
import com.kidyoh.snapsort.ui.IconBadge
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.NavDestination
import com.kidyoh.snapsort.ui.SheetButtons
import com.kidyoh.snapsort.ui.SheetHeading

private val destinations = listOf(
    NavDestination(Icons.Outlined.PhotoLibrary, Icons.Rounded.PhotoLibrary, "Timeline"),
    NavDestination(Icons.Outlined.Apps, Icons.Rounded.Apps, "Apps"),
    NavDestination(Icons.Outlined.PhotoAlbum, Icons.Rounded.PhotoAlbum, "Albums"),
    NavDestination(Icons.Outlined.CleaningServices, Icons.Rounded.CleaningServices, "Clean up"),
)

/** The four tabs with a floating pill nav over them. */
@Composable
fun Shell() {
    val app = LocalApp.current
    val lib = app.lib
    var tab by rememberSaveable { mutableIntStateOf(0) }
    var navHidden by remember { mutableStateOf(false) }
    var prompted by remember { mutableStateOf(false) }
    val holder = rememberSaveableStateHolder()

    // If the app closed unexpectedly last time, offer to share the details.
    LaunchedEffect(Unit) {
        val report = lib.takeCrashReport() ?: return@LaunchedEffect
        prompted = true // don't stack the usage prompt on top
        val share = app.sheets.show<Boolean> {
            SheetHeading(
                "Sorry about", "that.",
                "SnapSort closed unexpectedly last time. Sharing the details (phone model, Android version " +
                    "and where it failed, no screenshots) helps get it fixed.",
            )
            Column { SheetButtons("Share details", { done(true) }, "Not now", { done(false) }) }
        }
        if (share == true) lib.shareText(report)
    }

    // Asked once: the only exact way to know the app when the file name doesn't say.
    val wantsUsage = lib.loadedOnce && !lib.usageAccess && !lib.usagePromptShown && lib.unknownCount > 0
    LaunchedEffect(wantsUsage) {
        if (!wantsUsage || prompted) return@LaunchedEffect
        prompted = true
        app.askForUsageAccess()
    }

    Box(Modifier.fillMaxSize()) {
        Crossfade(tab, animationSpec = tween(180), label = "tabs") { t ->
            holder.SaveableStateProvider(t) {
                when (t) {
                    0 -> TimelineScreen(onSelecting = { navHidden = it })
                    1 -> AppsScreen()
                    2 -> AlbumsScreen()
                    else -> CleanupScreen()
                }
            }
        }
        AnimatedVisibility(
            !navHidden,
            modifier = Modifier.align(Alignment.BottomCenter).windowInsetsPadding(WindowInsets.navigationBars).padding(bottom = 18.dp),
            enter = slideInVertically(tween(320, easing = FastOutSlowInEasing)) { it * 2 },
            exit = slideOutVertically(tween(320)) { it * 2 },
        ) {
            FloatingNav(destinations, tab, { tab = it })
        }
    }
}

suspend fun AppState.askForUsageAccess() {
    lib.markUsagePromptShown()
    val count = lib.unknownCount
    val turnOn = sheets.show<Boolean> {
        IconBadge(Icons.AutoMirrored.Rounded.ManageSearch, Brand.violet, 52.dp)
        Spacer(Modifier.height(18.dp))
        SheetHeading(
            "One more", "step.",
            "${formatCount(count, "screenshot")} don't say which app ${if (count == 1) "it is" else "they are"} from. " +
                "Turn on Usage access and SnapSort looks up the app that was open at the exact moment you took each one, " +
                "and keeps doing it for new screenshots. Nothing leaves your phone.",
        )
        Column { SheetButtons("Turn on usage access", { done(true) }, "Not now", { done(false) }) }
    }
    if (turnOn == true) lib.openUsageAccess()
}

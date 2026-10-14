package com.kidyoh.snapsort.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import com.kidyoh.snapsort.MainActivity
import com.kidyoh.snapsort.data.Library
import com.kidyoh.snapsort.data.Section
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.Thumbs
import com.kidyoh.snapsort.ui.screens.GroupScreen
import com.kidyoh.snapsort.ui.screens.OnboardingScreen
import com.kidyoh.snapsort.ui.screens.Shell
import com.kidyoh.snapsort.ui.screens.SwipeScreen
import com.kidyoh.snapsort.ui.screens.ViewerScreen
import kotlinx.coroutines.CoroutineScope

/** Pages pushed over the tabs. */
sealed interface Route

/** A page of screenshots (one app, an album, a clean-up review) that stays in sync with the library. */
class GroupRoute(
    val title: String,
    val overline: String,
    val sections: (Library) -> List<Section>,
    val dot: Color? = null,
    val initialSelection: Set<Long> = emptySet(),
    val album: String? = null,
    val hint: String? = null,
    val emptyMessage: String = "Nothing here.",
    /** Shows a "Swipe through" button for these screenshots. */
    val swipe: ((Library) -> List<Shot>)? = null,
) : Route

class SwipeRoute(val shots: List<Shot>, val title: String = "Swipe to clean") : Route

class ViewerRoute(val shots: List<Shot>, val index: Int) : Route

internal class Entry(val id: Int, val route: Route)

@Stable
class AppState(val lib: Library, val thumbs: Thumbs, val scope: CoroutineScope) {
    val sheets = Sheets()
    val snacks = Snacks()
    var haptics: Haptics? = null
    private val stack = mutableStateListOf<Entry>()
    private var nextId = 0

    internal val top: Entry? get() = stack.lastOrNull()
    val hasPages get() = stack.isNotEmpty()

    fun push(route: Route) {
        stack += Entry(nextId++, route)
    }

    fun pop() {
        if (stack.isNotEmpty()) stack.removeAt(stack.lastIndex)
    }

    fun openApp(app: String) = push(
        GroupRoute(
            title = app,
            overline = "App",
            dot = colorFor(app),
            hint = if (app == Shot.OTHER) "These don't say which app they're from. Select some and tap Set app to file them." else null,
            sections = { lib -> com.kidyoh.snapsort.data.sectionsByMonth(lib.shots.filter { it.app == app }) },
            swipe = { lib -> lib.shots.filter { it.app == app }.reversed() },
        ),
    )

    fun openSwipe(shots: List<Shot>, title: String = "Swipe to clean") {
        if (shots.isEmpty()) snacks.show("Nothing to go through here") else push(SwipeRoute(shots, title))
    }
}

val LocalApp = staticCompositionLocalOf<AppState> { error("No app state") }

@Composable
fun SnapSortApp(lib: Library, thumbs: Thumbs) {
    val scope = rememberCoroutineScope()
    val app = remember { AppState(lib, thumbs, scope) }
    app.haptics = rememberHaptics()
    val dark = when (lib.themeMode) {
        1 -> false
        2 -> true
        else -> isSystemInDarkTheme()
    }
    val t = if (dark) Tokens.darkTokens else Tokens.light
    val activity = LocalContext.current as? MainActivity
    val viewerOpen = app.top?.route is ViewerRoute
    LaunchedEffect(dark, viewerOpen) { activity?.setBars(dark || viewerOpen) }

    CompositionLocalProvider(LocalTokens provides t, LocalApp provides app) {
        Box(Modifier.fillMaxSize().background(t.canvas)) {
            Crossfade(
                when {
                    lib.access == null -> 0
                    lib.hasAccess -> 2
                    else -> 1
                },
                animationSpec = tween(600),
                label = "root",
            ) { state ->
                when (state) {
                    0 -> Box(Modifier.fillMaxSize())
                    1 -> OnboardingScreen()
                    else -> Shell()
                }
            }

            BackHandler(enabled = app.hasPages) { app.pop() }
            val holder = rememberSaveableStateHolder()
            AnimatedContent(
                app.top,
                transitionSpec = {
                    val forward = (targetState?.id ?: -1) > (initialState?.id ?: -1)
                    val viewer = targetState?.route is ViewerRoute || initialState?.route is ViewerRoute
                    when {
                        viewer -> fadeIn(tween(320)) togetherWith fadeOut(tween(260))
                        forward -> (fadeIn(tween(320)) + slideInHorizontally(tween(380, easing = FastOutSlowInEasing)) { it / 16 }) togetherWith
                            fadeOut(tween(200))
                        else -> fadeIn(tween(200)) togetherWith
                            (fadeOut(tween(260)) + slideOutHorizontally(tween(300)) { it / 16 })
                    }
                },
                contentKey = { it?.id },
                label = "pages",
            ) { entry ->
                if (entry == null) return@AnimatedContent
                holder.SaveableStateProvider(entry.id) {
                    when (val r = entry.route) {
                        is GroupRoute -> GroupScreen(r)
                        is SwipeRoute -> SwipeScreen(r)
                        is ViewerRoute -> ViewerScreen(r)
                    }
                }
            }

            SheetHost(app.sheets)
            SnackHost(app.snacks)
        }
    }
}

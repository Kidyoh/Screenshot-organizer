package com.kidyoh.snapsort.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Lightbulb
import androidx.compose.material.icons.rounded.Swipe
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.data.formatBytes
import com.kidyoh.snapsort.data.formatCount
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.CircleButton
import com.kidyoh.snapsort.ui.EmptyState
import com.kidyoh.snapsort.ui.GroupRoute
import com.kidyoh.snapsort.ui.IconBadge
import com.kidyoh.snapsort.ui.Insets
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.Panel
import com.kidyoh.snapsort.ui.SelectableShots
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.pageHeader
import com.kidyoh.snapsort.ui.tokens
import com.kidyoh.snapsort.ui.wide

/** A pushed page of screenshots (one app, an album, a clean-up review). */
@Composable
fun GroupScreen(route: GroupRoute) {
    val app = LocalApp.current
    val lib = app.lib
    val sections = route.sections(lib)
    val shots = sections.flatMap { it.shots }
    Box(Modifier.fillMaxSize().background(tokens.canvas)) {
        SelectableShots(
            sections = sections,
            initialSelection = route.initialSelection,
            album = route.album,
            header = {
                pageHeader(
                    route.title,
                    overline = route.overline,
                    dot = route.dot,
                    subtitle = "${formatCount(shots.size, "screenshot")} · ${formatBytes(shots.sumOf { it.size })}",
                    actions = {
                        route.swipe?.let { list ->
                            CircleButton(Icons.Rounded.Swipe, "Swipe through", { app.openSwipe(list(lib), route.title) })
                        }
                    },
                )
            },
            leading = {
                if (route.hint != null && shots.isNotEmpty()) {
                    wide("hint") {
                        Panel(Modifier.padding(start = Insets.page, top = 18.dp, end = Insets.page), padding = PaddingValues(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                IconBadge(Icons.Rounded.Lightbulb, Brand.amber, 38.dp)
                                Spacer(Modifier.width(12.dp))
                                Text(route.hint, Type.body)
                            }
                        }
                    }
                }
            },
            empty = { EmptyState(Icons.Rounded.Check, "All clear", route.emptyMessage, bottomPadding = 80.dp) },
        )
    }
}

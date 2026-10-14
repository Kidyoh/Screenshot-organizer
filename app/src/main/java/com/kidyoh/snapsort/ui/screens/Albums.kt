package com.kidyoh.snapsort.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.PhotoAlbum
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.Info
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.data.Section
import com.kidyoh.snapsort.data.formatCount
import com.kidyoh.snapsort.ui.AppState
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.FannedStack
import com.kidyoh.snapsort.ui.GroupRoute
import com.kidyoh.snapsort.ui.Icon
import com.kidyoh.snapsort.ui.Insets
import com.kidyoh.snapsort.ui.LocalApp
import com.kidyoh.snapsort.ui.PillButton
import com.kidyoh.snapsort.ui.PillStyle
import com.kidyoh.snapsort.ui.SectionLabel
import com.kidyoh.snapsort.ui.SheetHeading
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.askForName
import com.kidyoh.snapsort.ui.colorFor
import com.kidyoh.snapsort.ui.confirm
import com.kidyoh.snapsort.ui.entrance
import com.kidyoh.snapsort.ui.pressable
import com.kidyoh.snapsort.ui.serif
import com.kidyoh.snapsort.ui.tokens
import kotlinx.coroutines.launch

/** Favourites plus the person's own albums. */
@Composable
fun AlbumsScreen() {
    val app = LocalApp.current
    val lib = app.lib
    val names = lib.albums.keys.toList()
    val favorites = lib.favoriteShots

    CardGrid {
        row("title") {
            TabTitle("Your", "albums.", if (names.isEmpty()) "Collect what matters" else formatCount(names.size, "album"))
        }
        row("favorites") {
            FavoritesCard(favorites.size, Modifier.padding(top = 10.dp).entrance(80, 14.dp, 450)) {
                app.push(
                    GroupRoute(
                        title = "Favorites", overline = "Album", dot = Brand.coral,
                        sections = { l -> l.favoriteShots.let { if (it.isEmpty()) emptyList() else listOf(Section("Newest first", it)) } },
                        emptyMessage = "Tap the heart on any screenshot to keep it here.",
                    ),
                )
            }
        }
        row("label") { SectionLabel("Your albums", Modifier.padding(start = 2.dp, top = 18.dp, bottom = 2.dp)) }
        itemsIndexed(names, key = { _, n -> "album-$n" }) { i, name ->
            val shots = lib.albumShots(name)
            GroupCard(
                name, shots, formatCount(shots.size, "screenshot"),
                onClick = { app.openAlbum(name) },
                onLongClick = { app.scope.launch { app.albumMenu(name) } },
                icon = Icons.Outlined.PhotoAlbum,
                modifier = Modifier.entrance(delayMs = 40 * (i % 10), fromY = 0.dp, durationMs = 400),
            )
        }
        item(key = "new") {
            NewAlbumCard { app.scope.launch { app.createAlbum() } }
        }
        navSpace()
    }
}

private fun AppState.openAlbum(name: String) = push(
    GroupRoute(
        title = name, overline = "Album", dot = colorFor(name), album = name,
        sections = { l -> l.albumShots(name).let { if (it.isEmpty()) emptyList() else listOf(Section("Newest first", it)) } },
        emptyMessage = "Long-press screenshots anywhere in SnapSort, then tap Album to add them here.",
    ),
)

private suspend fun AppState.createAlbum() {
    val name = askForName("New", "album", action = "Create") ?: return
    if (!lib.createAlbum(name) && name.isNotBlank()) snacks.show("You already have an album called that", Icons.Rounded.Info)
}

private suspend fun AppState.albumMenu(name: String) {
    val action = sheets.show<String> {
        SheetHeading(name, message = formatCount(lib.albumShots(name).size, "screenshot"))
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PillButton("Rename", { done("rename") }, icon = Icons.Outlined.Edit, style = PillStyle.Soft)
            PillButton("Delete album", { done("delete") }, icon = Icons.Rounded.Delete, style = PillStyle.Danger)
        }
    }
    when (action) {
        "rename" -> {
            val to = askForName("Rename", "album", initial = name) ?: return
            if (to.trim() != name && !lib.renameAlbum(name, to)) snacks.show("Couldn't rename to \"$to\"", Icons.Rounded.Info)
        }
        "delete" -> if (confirm("Delete", "album?", "The screenshots in \"$name\" stay on your phone.", "Delete album")) lib.deleteAlbum(name)
    }
}

@Composable
private fun FavoritesCard(count: Int, modifier: Modifier, onClick: () -> Unit) {
    val lib = LocalApp.current.lib
    Row(
        modifier.fillMaxWidth().heightIn(min = 176.dp).pressable(onClick, scale = 0.98f)
            .background(Brand.coral, RoundedCornerShape(Insets.radius))
            .padding(start = 22.dp, top = 20.dp, end = 12.dp, bottom = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Box(Modifier.background(Color.White.copy(alpha = 0.22f), CircleShape).padding(8.dp)) {
                Icon(Icons.Rounded.Favorite, Color.White, size = 20.dp)
            }
            Spacer(Modifier.height(34.dp))
            Text("Favorites", serif(34f, Color.White), maxLines = 1)
            Spacer(Modifier.height(4.dp))
            Text(
                if (count == 0) "Tap the heart on any screenshot" else formatCount(count, "screenshot"),
                Type.label, color = Color.White.copy(alpha = 0.85f),
            )
        }
        if (count > 0) FannedStack(lib.favoriteShots, cardWidth = 54.dp)
    }
}

@Composable
private fun NewAlbumCard(onClick: () -> Unit) {
    val t = tokens
    Box(Modifier.aspectRatio(0.8f).pressable(onClick, scale = 0.97f), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val w = 1.6.dp.toPx()
            drawRoundRect(
                t.faint,
                topLeft = androidx.compose.ui.geometry.Offset(w / 2, w / 2),
                size = androidx.compose.ui.geometry.Size(size.width - w, size.height - w),
                cornerRadius = CornerRadius(Insets.radius.toPx()),
                style = Stroke(w, pathEffect = PathEffect.dashPathEffect(floatArrayOf(6.dp.toPx(), 6.dp.toPx()))),
            )
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.size(52.dp).background(t.highlight, CircleShape), contentAlignment = Alignment.Center) {
                Icon(Icons.Rounded.Add, Color.White, size = 28.dp)
            }
            Spacer(Modifier.height(12.dp))
            Text("New album", Type.titleSmall)
        }
    }
}

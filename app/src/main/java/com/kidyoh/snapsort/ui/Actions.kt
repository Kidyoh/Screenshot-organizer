package com.kidyoh.snapsort.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.PhotoAlbum
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.AutoMode
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material.icons.automirrored.rounded.Label
import androidx.compose.material.icons.rounded.PhotoAlbum
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.data.AppSource
import com.kidyoh.snapsort.data.Shot
import com.kidyoh.snapsort.data.formatCount

suspend fun AppState.confirm(title: String, accent: String?, message: String, action: String, danger: Boolean = true): Boolean =
    sheets.show<Boolean> {
        SheetHeading(title, accent, message)
        androidx.compose.foundation.layout.Column {
            SheetButtons(action, { done(true) }, "Cancel", { done(false) }, if (danger) PillStyle.Danger else PillStyle.Primary)
        }
    } == true

/** Bins (or deletes) screenshots, confirming first where Android won't. */
suspend fun AppState.deleteShots(shots: List<Shot>): Boolean {
    if (shots.isEmpty()) return false
    val what = formatCount(shots.size, "screenshot")
    if (!lib.trashGoesToBin && !confirm(
            "Delete", if (shots.size == 1) "this?" else "these?",
            "$what will be removed from your phone for good.", "Delete $what",
        )
    ) return false
    return try {
        val ok = lib.trash(shots)
        // Android 11+ returns false when the person taps Cancel, which needs no
        // message. Older versions only fail when storage access is missing.
        if (ok) {
            haptics?.light()
            snacks.show(if (lib.trashGoesToBin) "Moved $what to the recycle bin" else "Deleted $what", Icons.Rounded.Delete)
        } else if (!lib.trashGoesToBin) {
            snacks.show("Couldn't delete. Allow storage access for SnapSort and try again.", Icons.Rounded.ErrorOutline)
        }
        ok
    } catch (e: Exception) {
        snacks.show("Could not delete: ${e.message}", Icons.Rounded.ErrorOutline)
        false
    }
}

suspend fun AppState.askForName(title: String, accent: String?, initial: String = "", action: String = "Save"): String? =
    sheets.show<String> {
        val t = tokens
        var text by remember { mutableStateOf(initial) }
        val focus = remember { FocusRequester() }
        LaunchedEffect(Unit) { focus.requestFocus() }
        SheetHeading(title, accent)
        BasicTextField(
            text,
            { text = it },
            Modifier.fillMaxWidth().focusRequester(focus),
            textStyle = Type.title.copy(color = t.ink),
            singleLine = true,
            cursorBrush = SolidColor(t.highlight),
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences, imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { done(text) }),
            decorationBox = { field ->
                Box(
                    Modifier.fillMaxWidth().background(t.track, RoundedCornerShape(50)).padding(horizontal = 22.dp, vertical = 18.dp),
                ) {
                    if (text.isEmpty()) Text("Receipts, Memes, Recipes…", Type.title, color = t.faint, maxLines = 1)
                    field()
                }
            },
        )
        Spacer(Modifier.height(16.dp))
        PillButton(action, { done(text) })
    }

@Composable
private fun ChoiceRow(leading: @Composable () -> Unit, title: String, sub: String? = null, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().pressable(onClick, scale = 0.98f).padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        leading()
        Spacer(Modifier.width(16.dp))
        Column(Modifier.weight(1f)) {
            Text(title, Type.title, maxLines = 1)
            if (sub != null) Text(sub, Type.bodySmall, color = tokens.muted)
        }
        Icon(Icons.Rounded.ChevronRight, tokens.faint)
    }
}

/** Pick an album (or make one) and add [shots] to it. */
suspend fun AppState.addToAlbum(shots: List<Shot>): Boolean {
    val newAlbum = "\u0000new"
    val choice = sheets.show<String> {
        val t = tokens
        SheetHeading("Add to", "album", formatCount(shots.size, "screenshot"))
        Column(Modifier.heightIn(max = LocalConfiguration.current.screenHeightDp.dp * 0.5f).verticalScroll(rememberScrollState())) {
            ChoiceRow(
                { Box(Modifier.size(48.dp).background(t.highlight, CircleShape), contentAlignment = Alignment.Center) { Icon(Icons.Rounded.Add, Color.White) } },
                "New album",
            ) { done(newAlbum) }
            for (name in lib.albums.keys) {
                val inside = lib.albumShots(name)
                ChoiceRow(
                    {
                        Box(Modifier.size(48.dp)) {
                            if (inside.isEmpty()) IconBadge(Icons.Outlined.PhotoAlbum, colorFor(name), 48.dp)
                            else RoundedShot(inside.first(), Modifier.size(48.dp), radius = 14.dp)
                        }
                    },
                    name,
                    formatCount(inside.size, "screenshot"),
                ) { done(name) }
            }
        }
    } ?: return false
    var album = choice
    if (choice == newAlbum) {
        album = askForName("New", "album", action = "Create")?.trim().orEmpty()
        if (album.isEmpty()) return false
    }
    lib.addToAlbum(album, shots)
    haptics?.light()
    snacks.show("Added to $album", Icons.Rounded.PhotoAlbum)
    return true
}

fun appSourceText(source: AppSource) = when (source) {
    AppSource.FileName -> "From the file name"
    AppSource.Usage -> "From the app that was open at the time"
    AppSource.Manual -> "You chose this"
    AppSource.Looks -> "From how it looks"
    AppSource.Unknown -> "Not known yet"
}

/** Lets the person file [shots] under an app by hand (or back to automatic). */
suspend fun AppState.setAppFor(shots: List<Shot>): Boolean {
    val other = "\u0000other"
    val automatic = "\u0000auto"
    val names = lib.apps.map { it.name }.filter { it != Shot.OTHER }.sortedBy { it.lowercase() }
    val anyManual = shots.any { it.appSource == AppSource.Manual }
    val choice = sheets.show<String> {
        val t = tokens
        @Composable
        fun row(leading: @Composable () -> Unit, title: String, value: String) {
            Row(
                Modifier.fillMaxWidth().pressable({ done(value) }, scale = 0.98f).padding(vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.width(40.dp), contentAlignment = Alignment.Center) { leading() }
                Spacer(Modifier.width(12.dp))
                Text(title, Type.title, Modifier.weight(1f), maxLines = 1)
                Icon(Icons.Rounded.ChevronRight, t.faint)
            }
        }
        SheetHeading("Which", "app?", "For ${formatCount(shots.size, "screenshot")}. Your choice always wins.")
        Column(Modifier.heightIn(max = LocalConfiguration.current.screenHeightDp.dp * 0.55f).verticalScroll(rememberScrollState())) {
            row({ Icon(Icons.Outlined.Edit, t.highlight) }, "Another app…", other)
            if (anyManual) row({ Icon(Icons.Rounded.AutoMode, t.muted) }, "Back to automatic", automatic)
            for (n in names) row({ Dot(colorFor(n), 12.dp) }, n, n)
        }
    } ?: return false
    val app: String? = when (choice) {
        other -> askForName("Which", "app?")?.trim()?.takeIf { it.isNotEmpty() } ?: return false
        automatic -> null
        else -> choice
    }
    lib.setApp(shots, app)
    snacks.show(if (app == null) "Back to automatic" else "Filed under $app", Icons.AutoMirrored.Rounded.Label)
    return true
}

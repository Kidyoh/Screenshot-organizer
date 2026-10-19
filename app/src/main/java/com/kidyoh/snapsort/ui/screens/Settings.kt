package com.kidyoh.snapsort.ui.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.rounded.Apps
import androidx.compose.material.icons.rounded.FolderOpen
import androidx.compose.material.icons.automirrored.rounded.ManageSearch
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.WifiOff
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.kidyoh.snapsort.BuildConfig
import com.kidyoh.snapsort.ui.AppState
import com.kidyoh.snapsort.ui.Brand
import com.kidyoh.snapsort.ui.IconBadge
import com.kidyoh.snapsort.ui.PillButton
import com.kidyoh.snapsort.ui.PillStyle
import com.kidyoh.snapsort.ui.PillTabs
import com.kidyoh.snapsort.ui.SectionLabel
import com.kidyoh.snapsort.ui.SheetHeading
import com.kidyoh.snapsort.ui.Text
import com.kidyoh.snapsort.ui.Type
import com.kidyoh.snapsort.ui.tokens
import kotlinx.coroutines.launch

fun AppState.showSettings() {
    scope.launch {
        sheets.show<Unit> {
            val t = tokens
            @Composable
            fun fact(icon: ImageVector, color: Color, title: String, body: String) {
                Row(Modifier.padding(bottom = 14.dp)) {
                    IconBadge(icon, color, 40.dp)
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(title, Type.titleSmall)
                        Spacer(Modifier.height(2.dp))
                        Text(body, Type.bodySmall, color = t.muted)
                    }
                }
            }
            Column(Modifier.verticalScroll(rememberScrollState())) {
                SheetHeading("Settings")
                SectionLabel("Appearance", Modifier.padding(start = 2.dp, bottom = 10.dp))
                PillTabs(listOf(0, 1, 2), { listOf("Auto", "Light", "Dark")[it] }, lib.themeMode, lib::setTheme)
                SectionLabel("How it works", Modifier.padding(start = 2.dp, top = 26.dp, bottom = 12.dp))
                fact(Icons.Rounded.FolderOpen, Brand.violet, "Reads your Screenshots folder",
                    "Anything saved in a folder called Screenshots shows up, including subfolders.")
                fact(Icons.Rounded.Apps, Brand.mint, "Sorts by app from the file name",
                    "Most phones write the app into the screenshot's name.")
                fact(Icons.Outlined.Visibility, Brand.coral, "Recognises apps by how they look",
                    "Fixed rules, no AI: well-known app colours and layouts, and matches with your own screenshots whose app is known.")
                fact(
                    Icons.AutoMirrored.Rounded.ManageSearch, Brand.amber, "Usage access: ${if (lib.usageAccess) "on" else "off"}",
                    if (lib.usageAccess) "For screenshots without the app in the name, SnapSort checks which app was open when you took them."
                    else "Turn it on so SnapSort can tell which app was open for screenshots without the app in the name.",
                )
                if (!lib.usageAccess) {
                    Box(Modifier.padding(start = 54.dp, bottom = 14.dp)) {
                        PillButton("Turn on usage access", lib::openUsageAccess, style = PillStyle.Soft, height = 42.dp, expand = false)
                    }
                }
                fact(Icons.Rounded.WifiOff, Brand.mint, "Private by design",
                    "No internet permission and no AI. Albums and favourites stay on this phone.")
                Spacer(Modifier.height(6.dp))
                PillButton(
                    if (lib.loading) "Rescanning…" else "Rescan screenshots", lib::refresh,
                    icon = Icons.Rounded.Refresh, style = PillStyle.Soft, busy = lib.loading,
                )
                Spacer(Modifier.height(10.dp))
                PillButton("Privacy policy", lib::openPrivacyPolicy, style = PillStyle.Soft)
                Spacer(Modifier.height(16.dp))
                Text("SnapSort ${BuildConfig.VERSION_NAME}", Type.bodySmall, Modifier.fillMaxWidth(), color = t.faint, align = androidx.compose.ui.text.style.TextAlign.Center)
            }
        }
    }
}

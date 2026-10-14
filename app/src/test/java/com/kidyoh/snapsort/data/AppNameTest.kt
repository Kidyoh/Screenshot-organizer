package com.kidyoh.snapsort.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AppNameTest {
    @Test fun samsungAndPixelKeepTheLabel() {
        assertEquals(AppHint.Label("WhatsApp"), parseAppHint("Screenshot_20240115-093012_WhatsApp.jpg"))
        assertEquals(AppHint.Label("Samsung Internet"), parseAppHint("Screenshot_20240115-093012_Samsung Internet.jpg"))
        assertEquals(AppHint.Label("9GAG"), parseAppHint("Screenshot_20240115_093012_9GAG.png"))
        assertEquals(AppHint.Label("X"), parseAppHint("Screenshot_20240115-093012_X.jpg"))
    }

    @Test fun xiaomiGivesThePackage() {
        assertEquals(
            AppHint.Package("com.android.chrome"),
            parseAppHint("Screenshot_2023-05-12-14-30-12-123_com.android.chrome.jpg"),
        )
    }

    @Test fun colorOsGivesThePackageHash() {
        assertEquals(
            AppHint.Hash("965bbf4d18d205f782c6b8409c5773a4"),
            parseAppHint("Screenshot_2023-08-12-10-11-12-34_965bbf4d18d205f782c6b8409c5773a4.jpg"),
        )
    }

    @Test fun namesWithoutAnAppGiveNull() {
        assertNull(parseAppHint("Screenshot_20240115-093012.png"))
        assertNull(parseAppHint("Screenshot 2024-01-15 at 10.30.12.png"))
        assertNull(parseAppHint("Screenshot_20240115-093012 (1).png"))
        assertNull(parseAppHint("Screenshot 2024-01-15 at 10.30.12 PM.png"))
        assertEquals(AppHint.Label("IMG"), parseAppHint("IMG_20240101_101010.jpg"))
    }

    @Test fun copySuffixesAreIgnored() {
        assertEquals(AppHint.Label("Chrome"), parseAppHint("Screenshot_20240115-093012_Chrome (2).jpg"))
    }

    @Test fun aSubfolderUnderScreenshotsWins() {
        assertEquals(AppHint.Label("Instagram"), parseAppHint("Screenshot_20240115-093012.png", "Pictures/Screenshots/Instagram/"))
        assertEquals(AppHint.Label("Chrome"), parseAppHint("Screenshot_20240115-093012_Chrome.png", "DCIM/Screenshots/"))
    }

    @Test fun prettifyKnownAndUnknownPackages() {
        assertEquals("TikTok", prettifyPackage("com.zhiliaoapp.musically"))
        assertEquals("Messenger", prettifyPackage("com.facebook.orca"))
        assertEquals("Spotify", prettifyPackage("com.spotify.music.beta"))
        assertEquals("Fitness", prettifyPackage("com.google.android.apps.fitness"))
        assertEquals("Example", prettifyPackage("net.example"))
    }
}

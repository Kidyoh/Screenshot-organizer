package com.kidyoh.snapsort.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.kidyoh.snapsort.R

/** Brand colours, taken from the app icon. */
object Brand {
    val violet = Color(0xFF6C4DFF)
    val coral = Color(0xFFFF5E8E)
    val amber = Color(0xFFFFB23F)
    val mint = Color(0xFF2EC4A6)
}

/** Surfaces and text colours that flip between light and dark mode. */
@Immutable
data class Tokens(
    val dark: Boolean,
    /** Page background. */
    val canvas: Color,
    /** Cards, sheets and circle buttons. */
    val card: Color,
    /** Hairlines. */
    val border: Color,
    /** Primary text. */
    val ink: Color,
    /** Secondary text. */
    val muted: Color,
    /** Tertiary text and placeholders. */
    val faint: Color,
    /** Progress tracks and image placeholders. */
    val track: Color,
    /** The floating navigation pill and selection dock. */
    val navBar: Color,
    /** Dark "hero" cards (storage summary). */
    val hero: Color,
    /** Violet highlight: fills with white on top, accents on large type. */
    val highlight: Color,
) {
    /** Soft shadow for floating things; none in dark mode. */
    val raised get() = !dark

    /** A soft wash of [color] for tinted panels. */
    fun wash(color: Color, strength: Float = 1f) = color.copy(alpha = (if (dark) 0.20f else 0.14f) * strength)

    companion object {
        val light = Tokens(
            dark = false,
            canvas = Color(0xFFF5F2ED),
            card = Color(0xFFFFFFFF),
            border = Color(0xFFE8E3DB),
            ink = Color(0xFF16151A),
            muted = Color(0xFF6E6A73),
            faint = Color(0xFFA9A4AD),
            track = Color(0xFFEBE6DE),
            navBar = Color(0xFF16151A),
            hero = Color(0xFF16151A),
            highlight = Brand.violet,
        )
        val darkTokens = Tokens(
            dark = true,
            canvas = Color(0xFF0B0B0D),
            card = Color(0xFF18171B),
            border = Color(0xFF2A282E),
            ink = Color(0xFFF5F3EF),
            muted = Color(0xFFA3A0A8),
            faint = Color(0xFF6C6970),
            track = Color(0xFF242228),
            navBar = Color(0xFF232127),
            hero = Color(0xFF1E1C22),
            highlight = Color(0xFF8C73FF),
        )
    }
}

val LocalTokens = staticCompositionLocalOf { Tokens.light }

val tokens: Tokens
    @Composable @ReadOnlyComposable get() = LocalTokens.current

val Jakarta = FontFamily(
    Font(R.font.jakarta_500, FontWeight.Medium),
    Font(R.font.jakarta_600, FontWeight.SemiBold),
    Font(R.font.jakarta_700, FontWeight.Bold),
    Font(R.font.jakarta_800, FontWeight.ExtraBold),
)

val Serif = FontFamily(Font(R.font.serif_italic, FontWeight.Normal, FontStyle.Italic))

/** The type scale (Plus Jakarta Sans). */
object Type {
    private fun s(size: Float, w: FontWeight, ls: Float = 0f, lh: Float? = null) = TextStyle(
        fontFamily = Jakarta,
        fontSize = size.sp,
        fontWeight = w,
        letterSpacing = ls.sp,
        lineHeight = lh?.let { (size * it).sp } ?: TextUnit.Unspecified,
    )

    val display = s(42f, FontWeight.ExtraBold, -1.6f, 1.0f)
    val headlineMedium = s(32f, FontWeight.ExtraBold, -1.1f, 1.05f)
    val headline = s(24f, FontWeight.ExtraBold, -0.6f, 1.1f)
    val titleLarge = s(20f, FontWeight.Bold, -0.3f)
    val title = s(16f, FontWeight.Bold, -0.2f)
    val titleSmall = s(14f, FontWeight.Bold)
    val bodyLarge = s(16f, FontWeight.Medium, lh = 1.45f)
    val body = s(14f, FontWeight.Medium, lh = 1.4f)
    val bodySmall = s(12.5f, FontWeight.Medium, lh = 1.35f)
    val label = s(14f, FontWeight.Bold)
    val labelMedium = s(12.5f, FontWeight.Bold)

    /** Small spaced capitals. */
    val overline = s(11f, FontWeight.ExtraBold, 1.6f)
}

/** The serif italic used for accent words in big titles. */
fun serif(size: Float, color: Color) = TextStyle(
    fontFamily = Serif,
    fontStyle = FontStyle.Italic,
    fontSize = (size * 1.14f).sp,
    lineHeight = 1.0.em,
    letterSpacing = (-0.4).sp,
    color = color,
)

object Insets {
    val page = 20.dp
    val gap = 12.dp
    val radius = 28.dp
    val tile = 14.dp

    /** Space to leave under scrolling content for the floating nav bar. */
    val navClearance = 124.dp
}

private val appColors = mapOf(
    "whatsapp" to Color(0xFF25D366),
    "whatsapp business" to Color(0xFF25D366),
    "chrome" to Color(0xFF4285F4),
    "instagram" to Color(0xFFE1306C),
    "spotify" to Color(0xFF1DB954),
    "maps" to Color(0xFF34A853),
    "gmail" to Color(0xFFEA4335),
    "telegram" to Color(0xFF27A7E7),
    "youtube" to Color(0xFFFF2D2D),
    "facebook" to Color(0xFF1877F2),
    "messenger" to Color(0xFF8B5CF6),
    "x" to Color(0xFF52525B),
    "tiktok" to Color(0xFF111827),
    "snapchat" to Color(0xFFFACC15),
    "calendar" to Color(0xFF3B82F6),
    "keep" to Color(0xFFF59E0B),
    "other" to Color(0xFF9A96A0),
)

private val palette = listOf(
    Brand.violet, Brand.coral, Brand.amber, Brand.mint,
    Color(0xFF3D8BFF), Color(0xFFFF7A45), Color(0xFFA855F7),
    Color(0xFF14B8A6), Color(0xFFE11D48), Color(0xFF65A30D),
)

/** A stable colour for an app or album name. */
fun colorFor(name: String): Color {
    val key = name.lowercase()
    appColors[key]?.let { return it }
    var h = 0
    for (c in key) h = (h * 31 + c.code) and 0x7fffffff
    return palette[h % palette.size]
}

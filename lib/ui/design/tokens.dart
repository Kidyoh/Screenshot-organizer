import 'package:flutter/material.dart';

/// Brand colours, taken from the app icon.
abstract final class Brand {
  static const violet = Color(0xFF6C4DFF);
  static const coral = Color(0xFFFF5E8E);
  static const amber = Color(0xFFFFB23F);
  static const mint = Color(0xFF2EC4A6);

  static const gradient = LinearGradient(
    colors: [violet, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Surfaces and text colours that flip between light and dark mode.
///
/// `primary` in the colour scheme is the violet highlight. It's used as a fill
/// with white on top, or as an accent on large type.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.canvas,
    required this.card,
    required this.border,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.track,
    required this.navBar,
    required this.hero,
    required this.raised,
  });

  /// Page background.
  final Color canvas;

  /// Cards, sheets and circle buttons.
  final Color card;

  /// Hairlines.
  final Color border;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Tertiary text and placeholders.
  final Color faint;

  /// Progress tracks and image placeholders.
  final Color track;

  /// The floating navigation pill and selection dock.
  final Color navBar;

  /// Dark "hero" cards (storage summary).
  final Color hero;

  /// Soft shadow for floating things; empty in dark mode.
  final List<BoxShadow> raised;

  static const light = AppTokens(
    canvas: Color(0xFFF5F2ED),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE8E3DB),
    ink: Color(0xFF16151A),
    muted: Color(0xFF6E6A73),
    faint: Color(0xFFA9A4AD),
    track: Color(0xFFEBE6DE),
    navBar: Color(0xFF16151A),
    hero: Color(0xFF16151A),
    raised: [
      BoxShadow(color: Color(0x14000000), blurRadius: 28, offset: Offset(0, 12)),
    ],
  );

  static const dark = AppTokens(
    canvas: Color(0xFF0B0B0D),
    card: Color(0xFF18171B),
    border: Color(0xFF2A282E),
    ink: Color(0xFFF5F3EF),
    muted: Color(0xFFA3A0A8),
    faint: Color(0xFF6C6970),
    track: Color(0xFF242228),
    navBar: Color(0xFF232127),
    hero: Color(0xFF1E1C22),
    raised: [],
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      canvas: l(canvas, other.canvas),
      card: l(card, other.card),
      border: l(border, other.border),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      track: l(track, other.track),
      navBar: l(navBar, other.navBar),
      hero: l(hero, other.hero),
      raised: t < 0.5 ? raised : other.raised,
    );
  }
}

extension DesignContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get highlight => Theme.of(this).colorScheme.primary;
}

abstract final class Insets {
  static const page = 20.0;
  static const gap = 12.0;
  static const radius = 28.0;
  static const tile = 14.0;

  /// Space to leave under scrolling content for the floating nav bar.
  static const navClearance = 124.0;
}

/// The serif italic used for accent words in big titles.
TextStyle serifAccent(double size, Color color) => TextStyle(
      fontFamily: 'InstrumentSerif',
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      fontSize: size * 1.14,
      height: 1.0,
      letterSpacing: -0.4,
      color: color,
    );

/// A soft wash of [color] for tinted panels.
Color wash(Color color, BuildContext context, [double strength = 1]) =>
    color.withValues(alpha: (context.isDark ? 0.20 : 0.14) * strength);

const _appColors = <String, Color>{
  'whatsapp': Color(0xFF25D366),
  'whatsapp business': Color(0xFF25D366),
  'chrome': Color(0xFF4285F4),
  'instagram': Color(0xFFE1306C),
  'spotify': Color(0xFF1DB954),
  'maps': Color(0xFF34A853),
  'gmail': Color(0xFFEA4335),
  'telegram': Color(0xFF27A7E7),
  'youtube': Color(0xFFFF2D2D),
  'facebook': Color(0xFF1877F2),
  'messenger': Color(0xFF8B5CF6),
  'x': Color(0xFF52525B),
  'tiktok': Color(0xFF111827),
  'snapchat': Color(0xFFFACC15),
  'calendar': Color(0xFF3B82F6),
  'keep': Color(0xFFF59E0B),
  'other': Color(0xFF9A96A0),
};

const _palette = [
  Brand.violet,
  Brand.coral,
  Brand.amber,
  Brand.mint,
  Color(0xFF3D8BFF),
  Color(0xFFFF7A45),
  Color(0xFFA855F7),
  Color(0xFF14B8A6),
  Color(0xFFE11D48),
  Color(0xFF65A30D),
];

/// A stable colour for an app or album name.
Color colorFor(String name) {
  final key = name.toLowerCase();
  final known = _appColors[key];
  if (known != null) return known;
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _palette[h % _palette.length];
}

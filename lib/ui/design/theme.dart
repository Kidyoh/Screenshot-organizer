import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import 'tokens.dart';

const fontFamily = 'PlusJakartaSans';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final t = dark ? AppTokens.dark : AppTokens.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? const Color(0xFF8C73FF) : Brand.violet,
    onPrimary: Colors.white,
    primaryContainer: wash0(Brand.violet, dark),
    onPrimaryContainer: t.ink,
    secondary: Brand.coral,
    onSecondary: Colors.white,
    secondaryContainer: t.track,
    onSecondaryContainer: t.ink,
    tertiary: Brand.amber,
    onTertiary: t.ink,
    error: const Color(0xFFE5484D),
    onError: Colors.white,
    surface: t.canvas,
    onSurface: t.ink,
    onSurfaceVariant: t.muted,
    surfaceContainerLowest: t.card,
    surfaceContainerLow: t.card,
    surfaceContainer: t.card,
    surfaceContainerHigh: t.card,
    surfaceContainerHighest: t.track,
    outline: t.faint,
    outlineVariant: t.border,
    inverseSurface: t.ink,
    onInverseSurface: t.canvas,
    inversePrimary: Brand.violet,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: fontFamily,
    extensions: [t],
  );
  final text = _textTheme(base.textTheme, t);

  return base.copyWith(
    scaffoldBackgroundColor: t.canvas,
    canvasColor: t.canvas,
    textTheme: text,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: SoftSlideTransitionsBuilder()},
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: t.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.navBar,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionHandleColor: scheme.primary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: t.track,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.navBar,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: text.labelMedium?.copyWith(color: Colors.white),
    ),
  );
}

Color wash0(Color c, bool dark) => c.withValues(alpha: dark ? 0.22 : 0.14);

TextTheme _textTheme(TextTheme base, AppTokens t) {
  TextStyle s(double size, FontWeight w, {double ls = 0, double? h, Color? c}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        height: h,
        color: c ?? t.ink,
      );
  return base.copyWith(
    displaySmall: s(42, FontWeight.w800, ls: -1.6, h: 1.0),
    headlineMedium: s(32, FontWeight.w800, ls: -1.1, h: 1.05),
    headlineSmall: s(24, FontWeight.w800, ls: -0.6, h: 1.1),
    titleLarge: s(20, FontWeight.w700, ls: -0.3),
    titleMedium: s(16, FontWeight.w700, ls: -0.2),
    titleSmall: s(14, FontWeight.w700),
    bodyLarge: s(16, FontWeight.w500, h: 1.45),
    bodyMedium: s(14, FontWeight.w500, h: 1.4),
    bodySmall: s(12.5, FontWeight.w500, h: 1.35, c: t.muted),
    labelLarge: s(14, FontWeight.w700),
    labelMedium: s(12.5, FontWeight.w700),
    labelSmall: s(11, FontWeight.w800, ls: 1.6, c: t.muted),
  );
}

/// Pages fade in while sliding a short way from the right.
class SoftSlideTransitionsBuilder extends PageTransitionsBuilder {
  const SoftSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

/// Bouncy scrolling everywhere, no glow.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

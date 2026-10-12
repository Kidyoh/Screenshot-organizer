import 'package:flutter/material.dart';

/// Transparent route so the hero flight lands on a black backdrop the
/// viewer controls (it fades while you swipe down to close).
Route<T> viewerRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

Route<T> pageRoute<T>(WidgetBuilder builder) =>
    MaterialPageRoute<T>(builder: builder);

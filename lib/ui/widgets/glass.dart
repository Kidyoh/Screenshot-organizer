import 'dart:ui';

import 'package:flutter/material.dart';

import 'pressable.dart';

/// Frosted glass, for controls that float over screenshots.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 22,
    this.padding,
    this.dark = true,
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;

  /// Darker tint for use over bright images.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            color: dark
                ? Colors.black.withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.iconSize = 22,
    this.tooltip,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget b = Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Glass(
        radius: size / 2,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
    if (tooltip != null) {
      b = Semantics(button: true, label: tooltip, child: Tooltip(message: tooltip!, child: b));
    }
    return b;
  }
}

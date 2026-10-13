import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design/tokens.dart';
import 'pressable.dart';

/// White (or dark) circular icon button, used in headers.
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 46,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  /// Ink-filled instead of card-coloured.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final button = Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? t.ink : t.card,
          shape: BoxShape.circle,
          boxShadow: filled ? null : t.raised,
        ),
        child: Icon(icon, size: size * 0.46, color: filled ? t.canvas : t.ink),
      ),
    );
    return tooltip == null
        ? button
        : Semantics(
            button: true,
            label: tooltip,
            child: Tooltip(message: tooltip!, child: button),
          );
  }
}

/// Stadium button: violet for the main action, card-coloured for others.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.style = PillStyle.primary,
    this.busy = false,
    this.height = 56,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final PillStyle style;
  final bool busy;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = switch (style) {
      PillStyle.primary => (context.highlight, Colors.white),
      PillStyle.ink => (t.ink, t.canvas),
      PillStyle.soft => (t.track, t.ink),
      PillStyle.danger => (Brand.coral, Colors.white),
    };
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: height * 0.36, color: fg),
            SizedBox(width: height * 0.15),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge?.copyWith(
                    color: fg, fontSize: height >= 50 ? 15 : 13.5)),
          ),
        ],
      ],
    );
    return Pressable(
      onTap: busy ? null : onTap,
      scale: 0.96,
      child: Opacity(
        opacity: onTap == null && !busy ? 0.45 : 1,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: height * 0.42),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: content,
        ),
      ),
    );
  }
}

enum PillStyle { primary, ink, soft, danger }

/// Small spaced capitals above a section.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final String? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: text.toUpperCase()),
          if (trailing != null)
            TextSpan(text: '   $trailing', style: TextStyle(color: t.faint)),
        ]),
        style: context.text.labelSmall,
      ),
    );
  }
}

/// Big screen title, with the last word set in the serif italic accent.
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.lead,
    this.accent,
    this.overline,
    this.size = 38,
  });

  final String lead;
  final String? accent;
  final String? overline;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = context.text.displaySmall!.copyWith(fontSize: size);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null) ...[
          Text(overline!,
              style: context.text.bodyMedium?.copyWith(
                  color: context.tokens.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
        ],
        Text.rich(
          TextSpan(children: [
            TextSpan(text: lead),
            if (accent != null) ...[
              const TextSpan(text: ' '),
              TextSpan(text: accent, style: serifAccent(size, context.highlight)),
            ],
          ]),
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// The rounded card everything sits on.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.onLongPress,
    this.radius = Insets.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? context.tokens.card,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    return onTap == null && onLongPress == null
        ? box
        : Pressable(onTap: onTap, onLongPress: onLongPress, scale: 0.98, child: box);
  }
}

/// A rounded square with a tinted icon.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: wash(color, context, 1.2),
          borderRadius: BorderRadius.circular(size * 0.34),
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      );
}

/// Horizontally scrolling filter pills; the selected one is filled.
class PillFilters<T> extends StatelessWidget {
  const PillFilters({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: Insets.page),
  });

  /// (value, label, count) — value null means "all".
  final List<(T?, String, int?)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (value, label, count) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Pressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: value == selected ? t.ink : t.card,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: label),
                      if (count != null)
                        TextSpan(
                          text: '  $count',
                          style: TextStyle(
                              color: value == selected ? t.faint : t.faint,
                              fontWeight: FontWeight.w600),
                        ),
                    ]),
                    style: context.text.labelLarge?.copyWith(
                        color: value == selected ? t.canvas : t.ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Segmented pill control with a sliding thumb.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.height = 46,
    this.background,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final index = values.indexOf(selected);
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background ?? t.track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / values.length;
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: w * index,
            top: 0,
            bottom: 0,
            width: w,
            child: Container(
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(999),
                boxShadow: t.raised,
              ),
            ),
          ),
          Row(children: [
            for (final v in values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: v == selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (v == selected) return;
                      HapticFeedback.selectionClick();
                      onChanged(v);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: context.text.labelLarge!.copyWith(
                            fontSize: 13.5,
                            color: v == selected ? t.ink : t.muted),
                        child: Text(labelOf(v)),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      }),
    );
  }
}

/// Friendly empty screen with an orbiting-icon illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.bottomPadding = Insets.navClearance,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget orbit(IconData i, Color c) => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: t.card,
            shape: BoxShape.circle,
            border: Border.all(color: t.ink, width: 1.5),
          ),
          child: Icon(i, size: 18, color: c),
        );
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(36, 24, 36, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 130,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: context.highlight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: Colors.white),
                ),
                Positioned(left: 0, top: 10, child: orbit(Icons.auto_awesome_rounded, Brand.amber)),
                Positioned(right: 2, bottom: 6, child: orbit(Icons.favorite_rounded, Brand.coral)),
              ]),
            ).animate().scale(
                begin: const Offset(0.85, 0.85),
                duration: 500.ms,
                curve: Curves.easeOutBack),
            const SizedBox(height: 22),
            Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: context.text.bodyMedium?.copyWith(color: t.muted),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

/// A rounded bar split into coloured parts.
class SegmentBar extends StatelessWidget {
  const SegmentBar({super.key, required this.parts, this.height = 12, this.track});

  /// (fraction, colour) pairs; fractions should add up to at most 1.
  final List<(double, Color)> parts;
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: track ?? context.tokens.track,
        child: Row(children: [
          for (final (i, (f, c)) in parts.indexed)
            if (f > 0)
              Flexible(
                flex: (f * 1000).round().clamp(1, 1000),
                child: Container(
                  margin: EdgeInsets.only(right: i == parts.length - 1 ? 0 : 2),
                  color: c,
                ),
              ),
          if (parts.fold<double>(0, (s, p) => s + p.$1) < 0.999)
            Flexible(
              flex: ((1 - parts.fold<double>(0, (s, p) => s + p.$1)) * 1000)
                  .round()
                  .clamp(1, 1000),
              child: const SizedBox.shrink(),
            ),
        ]),
      ),
    );
  }
}

/// Counts up to [value] whenever it changes.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.format, this.style});

  final double value;
  final String Function(double) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Text(format(v), style: style),
      );
}

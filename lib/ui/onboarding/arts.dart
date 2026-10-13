import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/demo.dart';
import '../design/tokens.dart';

/// A screenshot card used in the onboarding art.
class _Card extends StatelessWidget {
  const _Card(this.asset, {this.width = 120});
  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: width * 2.1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.13),
          border: Border.all(color: context.tokens.card, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.11),
          child: Image.asset(demoAssetPath(asset),
              fit: BoxFit.cover, alignment: Alignment.topCenter, cacheWidth: 360),
        ),
      );
}

Widget _progress(bool active, Widget Function(double t) builder,
        {Duration duration = const Duration(milliseconds: 1300), Curve curve = Curves.easeOutBack}) =>
    TweenAnimationBuilder<double>(
      tween: Tween(end: active ? 1 : 0),
      duration: duration,
      curve: curve,
      builder: (context, t, _) => builder(t),
    );

/// A messy pile of screenshots fanning out.
class FanArt extends StatelessWidget {
  const FanArt({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    const assets = [
      'Screenshot_20261008-081210_Maps',
      'Screenshot_20261006-171932_Spotify',
      'Screenshot_20261012-091522_WhatsApp',
      'Screenshot_20261007-221804_Instagram',
      'Screenshot_20261010-143010_Chrome',
    ];
    const angles = [-18.0, -9.0, 0.0, 9.0, 18.0];
    return _progress(active, (t) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Brand.violet.withValues(alpha: context.isDark ? 0.16 : 0.10),
              ),
            ),
            for (var i = 0; i < assets.length; i++)
              Transform.translate(
                offset: Offset((i - 2) * 16.0 * t, (i - 2).abs() * 8.0 * t),
                child: Transform.rotate(
                  angle: angles[i] * t * math.pi / 180,
                  alignment: const Alignment(0, 2.2),
                  child: _Card(assets[i], width: 108),
                ),
              ),
          ],
        ));
  }
}

/// Screenshots dropping into labelled piles, one per app.
class SortArt extends StatelessWidget {
  const SortArt({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    const piles = [
      ('WhatsApp', ['Screenshot_20261011-201244_WhatsApp', 'Screenshot_20261012-091522_WhatsApp']),
      ('Chrome', ['Screenshot_20261009-190533_Chrome', 'Screenshot_20261010-143010_Chrome']),
      ('Maps', ['Screenshot_20261008-081210_Maps', 'Screenshot_20261008-081210_Maps']),
    ];
    return _progress(active, (t) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, (name, cards)) in piles.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 92,
                    height: 190,
                    child: Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
                      for (final (j, a) in cards.indexed)
                        Transform.translate(
                          offset: Offset(0, -12.0 * j - (1 - _stagger(t, i * 2 + j)) * 260),
                          child: Opacity(
                            opacity: _stagger(t, i * 2 + j).clamp(0.0, 1.0),
                            child: Transform.rotate(
                              angle: (j == 0 ? -4 : 5) * math.pi / 180,
                              child: _Card(a, width: 80),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: context.tokens.card,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: context.tokens.raised,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: colorFor(name), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(name, style: context.text.labelMedium),
                      ]),
                    ),
                  ),
                ]),
              ),
          ],
        ), duration: const Duration(milliseconds: 1600), curve: Curves.easeOut);
  }

  static double _stagger(double t, int i) =>
      Curves.easeOutBack.transform(((t * 1.6) - i * 0.12).clamp(0.0, 1.0));
}

/// A duplicate copy flying off into the bin, freeing space.
class CleanArt extends StatelessWidget {
  const CleanArt({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    const asset = 'Screenshot_20261005-110245_Bank';
    return _progress(active, (t) {
      final fly = Curves.easeInOutCubic.transform((t * 1.3).clamp(0.0, 1.0));
      final pop = Curves.easeOutBack.transform(((t - 0.6) / 0.4).clamp(0.0, 1.0));
      return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        Transform.translate(
          offset: Offset(-34, 0),
          child: Transform.rotate(angle: -6 * math.pi / 180, child: const _Card(asset, width: 122)),
        ),
        Transform.translate(
          offset: Offset(34 + fly * 70, fly * 120),
          child: Transform.rotate(
            angle: (6 + fly * 40) * math.pi / 180,
            child: Transform.scale(
              scale: 1 - fly * 0.65,
              child: Opacity(opacity: 1 - fly * 0.8, child: const _Card(asset, width: 122)),
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 0,
          child: Transform.scale(
            scale: 0.6 + 0.4 * fly,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Brand.coral,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Brand.coral.withValues(alpha: 0.4), blurRadius: 20)],
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
        Positioned(
          top: 6,
          child: Transform.scale(
            scale: pop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.tokens.navBar,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome_rounded, color: Brand.amber, size: 18),
                const SizedBox(width: 8),
                Text('2.4 MB freed', style: context.text.labelLarge?.copyWith(color: Colors.white)),
              ]),
            ),
          ),
        ),
      ]);
    }, duration: const Duration(milliseconds: 1700), curve: Curves.linear);
  }
}

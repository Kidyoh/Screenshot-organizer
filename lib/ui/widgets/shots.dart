import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../data/shot.dart';
import '../design/tokens.dart';
import '../scope.dart';
import 'common.dart';

/// Which screenshots are ticked.
class Selection extends ChangeNotifier {
  Selection([Iterable<int> initial = const []]) : ids = {...initial};
  final Set<int> ids;

  bool contains(Shot s) => ids.contains(s.id);

  void toggle(Shot s) {
    ids.contains(s.id) ? ids.remove(s.id) : ids.add(s.id);
    notifyListeners();
  }

  void setAll(Iterable<Shot> shots, bool selected) {
    for (final s in shots) {
      selected ? ids.add(s.id) : ids.remove(s.id);
    }
    notifyListeners();
  }

  void clear() {
    if (ids.isEmpty) return;
    ids.clear();
    notifyListeners();
  }
}

ImageProvider thumbProvider(Shot shot) => shot.asset != null
    ? ResizeImage(AssetImage(shot.asset!), width: 360)
    : AssetEntityImageProvider(
        shot.entity,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize(270, 585),
        thumbnailFormat: ThumbnailFormat.jpeg,
      );

/// A sharper image for big cards: the file itself, capped at phone width.
ImageProvider largeProvider(Shot shot) {
  if (shot.asset != null) return AssetImage(shot.asset!);
  if (shot.path.isNotEmpty) return ResizeImage(FileImage(File(shot.path)), width: 1080);
  return thumbProvider(shot);
}

/// Thumbnail that fades in once decoded, on a placeholder tint.
class ShotThumb extends StatelessWidget {
  const ShotThumb(this.shot, {super.key, this.fit = BoxFit.cover});
  final Shot shot;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.tokens.track,
      child: Image(
        image: thumbProvider(shot),
        fit: fit,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
          opacity: sync || frame != null ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        ),
        errorBuilder: (_, _, _) => Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 20, color: context.tokens.faint),
        ),
      ),
    );
  }
}

/// Rounded thumbnail with a hairline edge.
class RoundedShot extends StatelessWidget {
  const RoundedShot(this.shot, {super.key, this.radius = Insets.tile});
  final Shot shot;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: Stack(fit: StackFit.expand, children: [
        ShotThumb(shot),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(
                color: (context.isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.07)),
          ),
        ),
      ]),
    );
  }
}

/// A grid cell: tap to open, long-press to start selecting.
class ShotTile extends StatelessWidget {
  const ShotTile({
    super.key,
    required this.shot,
    required this.selection,
    required this.onOpen,
    this.heroTag,
  });

  final Shot shot;
  final Selection selection;
  final VoidCallback onOpen;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final selecting = selection.ids.isNotEmpty;
    final selected = selection.contains(shot);
    final favorite = LibraryScope.of(context).isFavorite(shot);
    final hl = context.highlight;
    Widget image = RoundedShot(shot, radius: selected ? 10 : Insets.tile);
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return Semantics(
      image: true,
      selected: selected,
      label: '${shot.app} screenshot, ${shortDate(shot.date)}',
      child: GestureDetector(
        onTap: () {
          if (selecting) {
            HapticFeedback.selectionClick();
            selection.toggle(shot);
          } else {
            onOpen();
          }
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          selection.toggle(shot);
        },
        child: Stack(fit: StackFit.expand, children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(selected ? 7 : 0),
            child: image,
          ),
          if (favorite)
            Positioned(
              left: selected ? 12 : 6,
              bottom: selected ? 12 : 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Brand.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.favorite_rounded, size: 12, color: Colors.white),
              ),
            ),
          if (selecting)
            Positioned(
              right: 6,
              top: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? hl : Colors.black.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                    : null,
              ),
            ),
        ]),
      ),
    );
  }
}

/// Up to three screenshots fanned out like a hand of cards (the app icon's motif).
class FannedStack extends StatelessWidget {
  const FannedStack({super.key, required this.shots, this.cardWidth = 58, this.spread = 11});

  final List<Shot> shots;
  final double cardWidth;
  final double spread;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cards = shots.take(3).toList().reversed.toList();
    final h = cardWidth * 2.05;
    const angles = [-1.0, 1.0, 0.0];
    return SizedBox(
      width: cardWidth * 2.2,
      height: h + 12,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (cards.isEmpty)
            Container(
              width: cardWidth,
              height: h,
              decoration: BoxDecoration(
                color: t.card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(cardWidth * 0.16),
              ),
            ),
          for (final (i, s) in cards.indexed)
            Transform.translate(
              offset: Offset(
                  cards.length == 1 ? 0 : angles[i + 3 - cards.length] * cardWidth * 0.42, 0),
              child: Transform.rotate(
                angle: (cards.length == 1 ? 0 : angles[i + 3 - cards.length]) *
                    spread *
                    3.14159 /
                    180,
                child: Container(
                  width: cardWidth,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardWidth * 0.16),
                    border: Border.all(color: t.card, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: RoundedShot(s, radius: cardWidth * 0.13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grid section header: label + count, with "Select all" while selecting.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.section, required this.selection});
  final Section section;
  final Selection selection;

  @override
  Widget build(BuildContext context) {
    final selecting = selection.ids.isNotEmpty;
    final all = selecting && section.shots.every(selection.contains);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.page + 2, 26, Insets.page - 6, 12),
      child: Row(children: [
        Expanded(
          child: SectionLabel(section.title,
              trailing: section.subtitle ?? '${section.shots.length}'),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: selecting ? 1 : 0,
          child: IgnorePointer(
            ignoring: !selecting,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => selection.setAll(section.shots, !all),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(all ? 'Deselect' : 'Select all',
                    style: context.text.labelMedium?.copyWith(color: context.highlight)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Slivers for a sectioned 3-up grid of screenshots.
List<Widget> shotGridSlivers({
  required List<Section> sections,
  required Selection selection,
  required void Function(Shot) onOpen,
  String heroPrefix = 'shot',
}) =>
    [
      for (final section in sections) ...[
        SliverToBoxAdapter(child: SectionHeader(section: section, selection: selection)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.page - 4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              childAspectRatio: 0.56,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final shot = section.shots[i];
                return ShotTile(
                  key: ValueKey(shot.id),
                  shot: shot,
                  selection: selection,
                  heroTag: '$heroPrefix-${shot.id}',
                  onOpen: () => onOpen(shot),
                );
              },
              childCount: section.shots.length,
            ),
          ),
        ),
      ],
    ];

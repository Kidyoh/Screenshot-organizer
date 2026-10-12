import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../data/shot.dart';
import 'scope.dart';

/// Which screenshots are ticked in a grid.
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
    ids.clear();
    notifyListeners();
  }
}

/// A small, cached thumbnail straight from the phone's media store.
class ShotThumb extends StatelessWidget {
  const ShotThumb(this.shot, {super.key, this.fit = BoxFit.cover});
  final Shot shot;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ColoredBox(
      color: bg,
      child: Image(
        image: AssetEntityImageProvider(
          shot.entity,
          isOriginal: false,
          thumbnailSize: const ThumbnailSize(240, 420),
          thumbnailFormat: ThumbnailFormat.jpeg,
        ),
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 20),
        ),
      ),
    );
  }
}

class ShotTile extends StatelessWidget {
  const ShotTile({
    super.key,
    required this.shot,
    required this.selection,
    required this.onOpen,
  });

  final Shot shot;
  final Selection selection;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selecting = selection.ids.isNotEmpty;
    final selected = selection.contains(shot);
    final favorite = LibraryScope.of(context).isFavorite(shot);
    return GestureDetector(
      onTap: selecting ? () => selection.toggle(shot) : onOpen,
      onLongPress: () => selection.toggle(shot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(selected ? 6 : 0),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 8 : 10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShotThumb(shot),
              if (favorite)
                const Positioned(
                  left: 4,
                  bottom: 4,
                  child: Icon(Icons.favorite, size: 16, color: Colors.white,
                      shadows: [Shadow(blurRadius: 4)]),
                ),
              if (selecting)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 22,
                    color: selected ? scheme.primary : Colors.white,
                    shadows: const [Shadow(blurRadius: 4)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A scrolling grid of screenshots split into titled sections.
class ShotGrid extends StatelessWidget {
  const ShotGrid({
    super.key,
    required this.sections,
    required this.selection,
    required this.onOpen,
    this.leading = const [],
  });

  final List<Section> sections;
  final Selection selection;
  final void Function(Shot shot) onOpen;

  /// Extra slivers shown above the grid (banners, filters...).
  final List<Widget> leading;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) => CustomScrollView(
        slivers: [
          ...leading,
          for (final section in sections) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(section: section, selection: selection),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 124,
                  childAspectRatio: 0.6,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final shot = section.shots[i];
                    return ShotTile(
                      key: ValueKey(shot.id),
                      shot: shot,
                      selection: selection,
                      onOpen: () => onOpen(shot),
                    );
                  },
                  childCount: section.shots.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section, required this.selection});
  final Section section;
  final Selection selection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selecting = selection.ids.isNotEmpty;
    final allSelected =
        selecting && section.shots.every(selection.contains);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: section.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextSpan(
                  text: '  ${section.subtitle ?? section.shots.length}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ]),
            ),
          ),
          if (selecting)
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => selection.setAll(section.shots, !allSelected),
              child: Text(allSelected ? 'Deselect' : 'Select all'),
            ),
        ],
      ),
    );
  }
}

/// Centered icon + message for empty screens.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

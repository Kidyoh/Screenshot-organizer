import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/routes.dart';
import '../../data/shot.dart';
import '../actions.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../screens/viewer.dart';
import 'common.dart';
import 'nav.dart';
import 'shots.dart';

/// A scrolling page of sectioned screenshots with long-press multi-select,
/// a top selection bar and a floating action dock.
class SelectableShots extends StatefulWidget {
  const SelectableShots({
    super.key,
    required this.header,
    required this.sections,
    this.leading = const [],
    this.empty,
    this.initialSelection = const {},
    this.album,
    this.heroPrefix = 'shot',
    this.inTab = false,
  });

  /// Slivers at the top of the page (title, buttons…).
  final List<Widget> header;
  final List<Section> sections;

  /// Slivers between the header and the grid.
  final List<Widget> leading;
  final Widget? empty;
  final Set<int> initialSelection;

  /// Adds "Remove" to the dock when showing an album.
  final String? album;
  final String heroPrefix;

  /// Inside a main tab: leaves room for, and hides, the floating nav.
  final bool inTab;

  @override
  State<SelectableShots> createState() => _SelectableShotsState();
}

class _SelectableShotsState extends State<SelectableShots> {
  late final Selection _selection = Selection(widget.initialSelection)
    ..addListener(_syncNav);
  ValueNotifier<bool>? _navHidden;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navHidden = widget.inTab ? ShellScope.maybeOf(context)?.navHidden : null;
  }

  void _syncNav() => _navHidden?.value = _selection.ids.isNotEmpty;

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  List<Shot> get _visible => [for (final s in widget.sections) ...s.shots];

  void _open(Shot shot) {
    final all = _visible;
    Navigator.of(context).push(viewerRoute(
      (_) => ViewerPage(
        shots: all,
        initialIndex: all.indexOf(shot),
        heroPrefix: widget.heroPrefix,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) {
        final selected = _selection.ids.map(lib.byId).whereType<Shot>().toList();
        final selecting = selected.isNotEmpty;
        final visible = _visible;
        final bottom = (widget.inTab ? Insets.navClearance : 40) + pad.bottom;
        return PopScope(
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _selection.clear();
          },
          child: Stack(children: [
            CustomScrollView(slivers: [
              ...widget.header,
              ...widget.leading,
              if (visible.isEmpty && widget.empty != null)
                SliverFillRemaining(hasScrollBody: false, child: widget.empty!)
              else ...[
                ...shotGridSlivers(
                  sections: widget.sections,
                  selection: _selection,
                  onOpen: _open,
                  heroPrefix: widget.heroPrefix,
                ),
                SliverToBoxAdapter(child: SizedBox(height: bottom + (selecting ? 40 : 0))),
              ],
            ]),
            // Top selection bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !selecting,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  offset: selecting ? Offset.zero : const Offset(0, -1),
                  child: _SelectionBar(
                    count: selected.length,
                    allSelected: visible.isNotEmpty && visible.every(_selection.contains),
                    onClose: _selection.clear,
                    onToggleAll: () => _selection.setAll(
                        visible, !visible.every(_selection.contains)),
                  ),
                ),
              ),
            ),
            // Bottom dock
            Positioned(
              left: Insets.page,
              right: Insets.page,
              bottom: pad.bottom + 18,
              child: IgnorePointer(
                ignoring: !selecting,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  offset: selecting ? Offset.zero : const Offset(0, 2),
                  child: _dock(context, selected),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _dock(BuildContext context, List<Shot> selected) {
    final lib = LibraryScope.read(context);
    final allFavorite = selected.isNotEmpty && selected.every(lib.isFavorite);
    return SelectionDock(actions: [
      DockAction(Icons.photo_album_outlined, 'Album', () async {
        if (await addToAlbum(context, selected)) _selection.clear();
      }),
      DockAction(Icons.ios_share_rounded, 'Share', () => lib.share(selected)),
      DockAction(
        allFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        allFavorite ? 'Unlike' : 'Favorite',
        () {
          lib.setFavorite(selected, !allFavorite);
          _selection.clear();
        },
      ),
      if (widget.album != null)
        DockAction(Icons.remove_circle_outline_rounded, 'Remove', () {
          lib.removeFromAlbum(widget.album!, selected);
          _selection.clear();
        }),
      DockAction(Icons.delete_outline_rounded, 'Delete', () async {
        if (await deleteShots(context, selected)) _selection.clear();
      }, danger: true),
    ]);
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.allSelected,
    required this.onClose,
    required this.onToggleAll,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onClose;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      color: t.canvas,
      padding: EdgeInsets.fromLTRB(
          Insets.page, MediaQuery.paddingOf(context).top + 10, Insets.page, 14),
      child: Row(children: [
        CircleButton(icon: Icons.close_rounded, tooltip: 'Clear selection', onTap: onClose),
        const SizedBox(width: 14),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$count '),
              TextSpan(text: 'selected', style: serifAccent(26, context.highlight)),
            ]),
            style: context.text.headlineSmall?.copyWith(fontSize: 26),
          ).animate(key: ValueKey(count)).fadeIn(duration: 160.ms),
        ),
        PillButton(
          label: allSelected ? 'None' : 'All',
          icon: allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
          style: PillStyle.soft,
          height: 42,
          expand: false,
          onTap: onToggleAll,
        ),
      ]),
    );
  }
}

/// Standard top-of-page header for pushed pages: back button + title.
List<Widget> pageHeader(
  BuildContext context, {
  required String title,
  String? overline,
  String? subtitle,
  Color? dot,
  List<Widget> actions = const [],
}) {
  final pad = MediaQuery.paddingOf(context);
  return [
    SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(Insets.page, pad.top + 10, Insets.page, 0),
        child: Row(children: [
          CircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          for (final a in actions) ...[const SizedBox(width: 10), a],
        ]),
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Insets.page + 2, 22, Insets.page, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overline != null)
              Row(children: [
                if (dot != null) ...[
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                ],
                SectionLabel(overline),
              ]),
            const SizedBox(height: 6),
            Text(title,
                style: context.text.displaySmall?.copyWith(fontSize: 36),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
            ],
          ],
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
      ),
    ),
  ];
}

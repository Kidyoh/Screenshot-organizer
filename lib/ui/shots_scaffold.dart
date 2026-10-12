import 'package:flutter/material.dart';

import '../data/library.dart';
import '../data/shot.dart';
import 'actions.dart';
import 'scope.dart';
import 'shot_grid.dart';
import 'viewer.dart';

/// A page showing a sectioned grid of screenshots, with long-press
/// multi-select and the usual actions (album, share, delete...).
class ShotsScaffold extends StatefulWidget {
  const ShotsScaffold({
    super.key,
    required this.sections,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.actions = const [],
    this.leading = const [],
    this.initialSelection = const {},
    this.album,
    this.empty,
  });

  final List<Section> sections;
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget> actions;
  final List<Widget> leading;
  final Set<int> initialSelection;

  /// When showing an album, adds a "Remove from album" action.
  final String? album;
  final Widget? empty;

  @override
  State<ShotsScaffold> createState() => _ShotsScaffoldState();
}

class _ShotsScaffoldState extends State<ShotsScaffold> {
  late final Selection _selection = Selection(widget.initialSelection);

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  List<Shot> get _visible => [for (final s in widget.sections) ...s.shots];

  void _open(Shot shot) {
    final all = _visible;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ViewerPage(shots: all, initialIndex: all.indexOf(shot)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) {
        final selected = _selection.ids.map(lib.byId).whereType<Shot>().toList();
        final selecting = selected.isNotEmpty;
        final visible = _visible;
        return PopScope(
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _selection.clear();
          },
          child: Scaffold(
            appBar: selecting
                ? _selectionBar(context, selected, visible)
                : AppBar(
                    title: widget.titleWidget ??
                        _Title(title: widget.title ?? '', subtitle: widget.subtitle),
                    actions: widget.actions,
                  ),
            body: visible.isEmpty && widget.empty != null
                ? CustomScrollView(slivers: [
                    ...widget.leading,
                    SliverFillRemaining(hasScrollBody: false, child: widget.empty!),
                  ])
                : ShotGrid(
                    sections: widget.sections,
                    selection: _selection,
                    onOpen: _open,
                    leading: widget.leading,
                  ),
          ),
        );
      },
    );
  }

  AppBar _selectionBar(BuildContext context, List<Shot> selected, List<Shot> visible) {
    final lib = LibraryScope.read(context);
    final allFavorite = selected.every(lib.isFavorite);
    final allSelected = visible.every(_selection.contains);
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Clear selection',
        onPressed: _selection.clear,
      ),
      title: Text('${selected.length} selected'),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      actions: [
        IconButton(
          tooltip: allSelected ? 'Deselect all' : 'Select all',
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          onPressed: () => _selection.setAll(visible, !allSelected),
        ),
        IconButton(
          tooltip: 'Add to album',
          icon: const Icon(Icons.library_add_outlined),
          onPressed: () async {
            await addToAlbum(context, selected);
            _selection.clear();
          },
        ),
        IconButton(
          tooltip: 'Share',
          icon: const Icon(Icons.share_outlined),
          onPressed: () => lib.share(selected),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            if (await deleteShots(context, selected)) _selection.clear();
          },
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'fav':
                lib.setFavorite(selected, !allFavorite);
                _selection.clear();
              case 'remove':
                lib.removeFromAlbum(widget.album!, selected);
                _selection.clear();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'fav',
              child: Text(allFavorite ? 'Remove from favorites' : 'Add to favorites'),
            ),
            if (widget.album != null)
              PopupMenuItem(
                value: 'remove',
                child: Text('Remove from "${widget.album}"'),
              ),
          ],
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Text(subtitle!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// A standalone page of screenshots that stays in sync with the library.
class ShotListPage extends StatelessWidget {
  const ShotListPage({
    super.key,
    required this.title,
    required this.sections,
    this.initialSelection = const {},
    this.album,
    this.hint,
    this.emptyMessage = 'Nothing here.',
  });

  final String title;
  final List<Section> Function(Library lib) sections;
  final Set<int> initialSelection;
  final String? album;
  final String? hint;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final s = sections(lib);
    final count = s.fold<int>(0, (n, sec) => n + sec.shots.length);
    final size = s.expand((sec) => sec.shots).fold<int>(0, (n, x) => n + x.size);
    return ShotsScaffold(
      title: title,
      subtitle: '${formatCount(count, 'screenshot')} · ${formatBytes(size)}',
      sections: s,
      album: album,
      initialSelection: initialSelection,
      leading: [
        if (hint != null && count > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(hint!),
                ),
              ),
            ),
          ),
      ],
      empty: EmptyState(
        icon: Icons.check_circle_outline,
        title: 'All clear',
        message: emptyMessage,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data/shot.dart';
import 'actions.dart';
import 'scope.dart';
import 'shot_grid.dart';
import 'shots_scaffold.dart';

/// Favourites plus the user's own albums.
class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final names = lib.albums.keys.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await askForName(context, title: 'New album', action: 'Create');
          if (name == null || !context.mounted) return;
          if (!lib.createAlbum(name)) showSnack(context, 'That album already exists');
        },
        icon: const Icon(Icons.add),
        label: const Text('New album'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        children: [
          _AlbumTile(
            icon: Icons.favorite,
            name: 'Favorites',
            shots: lib.favoriteShots,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ShotListPage(
                title: 'Favorites',
                sections: (lib) => [
                  if (lib.favoriteShots.isNotEmpty) Section('Favorites', lib.favoriteShots),
                ],
                emptyMessage: 'Tap the heart on a screenshot to keep it here.',
              ),
            )),
          ),
          for (final name in names)
            _AlbumTile(
              icon: Icons.photo_album_outlined,
              name: name,
              shots: lib.albumShots(name),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ShotListPage(
                  title: name,
                  album: name,
                  sections: (lib) => [
                    if (lib.albumShots(name).isNotEmpty) Section(name, lib.albumShots(name)),
                  ],
                  emptyMessage:
                      'Long-press screenshots anywhere in SnapSort and tap the album button to add them here.',
                ),
              )),
              menu: (value) async {
                if (value == 'rename') {
                  final to = await askForName(context, title: 'Rename album', initial: name);
                  if (to != null && context.mounted && !lib.renameAlbum(name, to) && to.trim() != name) {
                    showSnack(context, 'Could not rename to "$to"');
                  }
                } else if (value == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete "$name"?'),
                      content: const Text('The screenshots themselves stay on your phone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete album')),
                      ],
                    ),
                  );
                  if (ok == true) lib.deleteAlbum(name);
                }
              },
            ),
          if (names.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: EmptyState(
                icon: Icons.collections_bookmark_outlined,
                title: 'Make your own albums',
                message:
                    'Create albums like "Receipts" or "Memes", then long-press screenshots and tap the album button to file them.',
              ),
            ),
        ],
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.icon,
    required this.name,
    required this.shots,
    required this.onTap,
    this.menu,
  });

  final IconData icon;
  final String name;
  final List<Shot> shots;
  final VoidCallback onTap;
  final ValueChanged<String>? menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 72,
                  child: shots.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                        )
                      : ShotThumb(shots.first),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(icon, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(formatCount(shots.length, 'screenshot'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (menu != null)
                PopupMenuButton<String>(
                  onSelected: menu,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete album')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

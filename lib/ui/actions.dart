import 'package:flutter/material.dart';

import '../data/shot.dart';
import 'scope.dart';

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Deletes (or bins) screenshots, confirming first where Android won't.
Future<bool> deleteShots(BuildContext context, List<Shot> shots) async {
  if (shots.isEmpty) return false;
  final lib = LibraryScope.read(context);
  final what = formatCount(shots.length, 'screenshot');
  if (!lib.trashGoesToBin) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Delete $what?'),
        content: const Text('They will be removed from your phone for good.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return false;
  }
  try {
    final ok = await lib.trash(shots);
    if (context.mounted && ok) {
      showSnack(
          context,
          lib.trashGoesToBin
              ? 'Moved $what to the recycle bin'
              : 'Deleted $what');
    }
    return ok;
  } catch (e) {
    if (context.mounted) showSnack(context, 'Could not delete: $e');
    return false;
  }
}

Future<String?> askForName(BuildContext context,
    {required String title, String initial = '', String action = 'Save'}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'e.g. Receipts, Memes, Recipes'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(action)),
      ],
    ),
  );
}

/// Lets the user pick an album (or create one) and adds [shots] to it.
Future<void> addToAlbum(BuildContext context, List<Shot> shots) async {
  final lib = LibraryScope.read(context);
  const newAlbum = '\u0000new';
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Add ${formatCount(shots.length, 'screenshot')} to…',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New album'),
            onTap: () => Navigator.pop(context, newAlbum),
          ),
          for (final name in lib.albums.keys)
            ListTile(
              leading: const Icon(Icons.photo_album_outlined),
              title: Text(name),
              trailing: Text('${lib.albumShots(name).length}'),
              onTap: () => Navigator.pop(context, name),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  var album = choice;
  if (choice == newAlbum) {
    final name = (await askForName(context, title: 'New album', action: 'Create'))?.trim();
    if (name == null || name.isEmpty || !context.mounted) return;
    album = name;
  }
  lib.addToAlbum(album, shots);
  showSnack(context, 'Added to "$album"');
}

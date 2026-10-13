import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/shot.dart';
import 'design/tokens.dart';
import 'scope.dart';
import 'widgets/common.dart';
import 'widgets/pressable.dart';
import 'widgets/shots.dart';

void showSnack(BuildContext context, String message, {IconData? icon}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 104),
      content: Row(children: [
        Icon(icon ?? Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
    ));
}

Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: builder(context),
          ),
        ),
      ),
    );

/// Sheet heading: big title with an optional serif accent and a message.
class SheetHeading extends StatelessWidget {
  const SheetHeading({super.key, required this.title, this.accent, this.message});
  final String title;
  final String? accent;
  final String? message;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(lead: title, accent: accent, size: 28),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!,
                style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
          ],
          const SizedBox(height: 20),
        ],
      );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? accent,
  required String message,
  required String action,
  bool danger = true,
}) async {
  final ok = await showAppSheet<bool>(
    context,
    (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeading(title: title, accent: accent, message: message),
        PillButton(
          label: action,
          style: danger ? PillStyle.danger : PillStyle.primary,
          onTap: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 10),
        PillButton(
          label: 'Cancel',
          style: PillStyle.soft,
          onTap: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Bins (or deletes) screenshots, confirming first where Android won't.
Future<bool> deleteShots(BuildContext context, List<Shot> shots) async {
  if (shots.isEmpty) return false;
  final lib = LibraryScope.read(context);
  final what = formatCount(shots.length, 'screenshot');
  if (!lib.trashGoesToBin &&
      !await confirm(context,
          title: 'Delete',
          accent: shots.length == 1 ? 'this?' : 'these?',
          message: '$what will be removed from your phone for good.',
          action: 'Delete $what')) {
    return false;
  }
  try {
    final ok = await lib.trash(shots);
    if (ok) HapticFeedback.lightImpact();
    // Android 11+ returns false when the person taps Cancel, which needs no
    // message. Older versions only fail when storage access is missing.
    if (!ok && !lib.trashGoesToBin && context.mounted) {
      showSnack(context, 'Couldn\'t delete. Allow storage access for SnapSort and try again.',
          icon: Icons.error_outline_rounded);
    }
    if (context.mounted && ok) {
      showSnack(
        context,
        lib.trashGoesToBin ? 'Moved $what to the recycle bin' : 'Deleted $what',
        icon: Icons.delete_outline_rounded,
      );
    }
    return ok;
  } catch (e) {
    if (context.mounted) showSnack(context, 'Could not delete: $e', icon: Icons.error_outline);
    return false;
  }
}

Future<String?> askForName(
  BuildContext context, {
  required String title,
  String? accent,
  String initial = '',
  String action = 'Save',
}) {
  final controller = TextEditingController(text: initial);
  return showAppSheet<String>(
    context,
    (context) {
      final t = context.tokens;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeading(title: title, accent: accent),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: context.text.titleMedium,
            decoration: InputDecoration(
              hintText: 'Receipts, Memes, Recipes…',
              hintStyle: context.text.titleMedium?.copyWith(color: t.faint),
              filled: true,
              fillColor: t.track,
              contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: 16),
          PillButton(label: action, onTap: () => Navigator.pop(context, controller.text)),
        ],
      );
    },
  );
}

/// Pick an album (or make one) and add [shots] to it.
Future<bool> addToAlbum(BuildContext context, List<Shot> shots) async {
  final lib = LibraryScope.read(context);
  const newAlbum = '\u0000new';
  final choice = await showAppSheet<String>(
    context,
    (context) {
      final t = context.tokens;
      Widget row({required Widget leading, required String title, String? sub, required VoidCallback onTap}) =>
          Pressable(
            onTap: onTap,
            scale: 0.98,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                leading,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: context.text.titleMedium),
                    if (sub != null) Text(sub, style: context.text.bodySmall),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: t.faint),
              ]),
            ),
          );
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeading(
              title: 'Add to',
              accent: 'album',
              message: formatCount(shots.length, 'screenshot'),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  row(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: context.highlight, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                    title: 'New album',
                    onTap: () => Navigator.pop(context, newAlbum),
                  ),
                  for (final name in lib.albums.keys)
                    row(
                      leading: SizedBox(
                        width: 48,
                        height: 48,
                        child: lib.albumShots(name).isEmpty
                            ? IconBadge(Icons.photo_album_outlined, color: colorFor(name), size: 48)
                            : RoundedShot(lib.albumShots(name).first, radius: 14),
                      ),
                      title: name,
                      sub: formatCount(lib.albumShots(name).length, 'screenshot'),
                      onTap: () => Navigator.pop(context, name),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return false;
  var album = choice;
  if (choice == newAlbum) {
    final name = (await askForName(context, title: 'New', accent: 'album', action: 'Create'))?.trim();
    if (name == null || name.isEmpty || !context.mounted) return false;
    album = name;
  }
  lib.addToAlbum(album, shots);
  HapticFeedback.lightImpact();
  showSnack(context, 'Added to $album', icon: Icons.photo_album_rounded);
  return true;
}

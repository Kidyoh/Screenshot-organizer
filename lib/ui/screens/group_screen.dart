import 'package:flutter/material.dart';

import '../../data/library.dart';
import '../../data/shot.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/selectable_shots.dart';

/// A pushed page of screenshots (one app, an album, a clean-up review) that
/// stays in sync with the library.
class GroupScreen extends StatelessWidget {
  const GroupScreen({
    super.key,
    required this.title,
    required this.overline,
    required this.sections,
    this.dot,
    this.initialSelection = const {},
    this.album,
    this.hint,
    this.emptyMessage = 'Nothing here.',
    this.actions = const [],
  });

  final String title;
  final String overline;
  final List<Section> Function(Library lib) sections;
  final Color? dot;
  final Set<int> initialSelection;
  final String? album;
  final String? hint;
  final String emptyMessage;

  /// Buttons at the top right (e.g. Swipe through).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final s = sections(lib);
    final shots = s.expand((sec) => sec.shots).toList();
    final size = shots.fold<int>(0, (n, x) => n + x.size);
    return Scaffold(
      body: SelectableShots(
        heroPrefix: 'group',
        initialSelection: initialSelection,
        album: album,
        header: pageHeader(
          context,
          title: title,
          overline: overline,
          dot: dot,
          subtitle: '${formatCount(shots.length, 'screenshot')} · ${formatBytes(size)}',
          actions: actions,
        ),
        leading: [
          if (hint != null && shots.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Insets.page, 18, Insets.page, 0),
                child: Panel(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    IconBadge(Icons.lightbulb_outline_rounded, color: Brand.amber, size: 38),
                    const SizedBox(width: 12),
                    Expanded(child: Text(hint!, style: context.text.bodyMedium)),
                  ]),
                ),
              ),
            ),
        ],
        sections: s,
        empty: EmptyState(
          icon: Icons.check_rounded,
          title: 'All clear',
          message: emptyMessage,
          bottomPadding: 80,
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/shot.dart';
import '../actions.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/shots.dart';

/// Full-screen, swipeable, pinch-to-zoom viewer. Swipe down to close.
class ViewerPage extends StatefulWidget {
  const ViewerPage({
    super.key,
    required this.shots,
    required this.initialIndex,
    this.heroPrefix = 'shot',
  });

  final List<Shot> shots;
  final int initialIndex;
  final String heroPrefix;

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final List<Shot> _items = [...widget.shots];
  late int _index = widget.initialIndex.clamp(0, _items.length - 1);
  late final int _heroIndex = _index;
  late final PageController _pages = PageController(initialPage: _index);
  bool _chrome = true;
  bool _zoomed = false;
  double _drag = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Shot get _current => _items[_index];

  Future<void> _delete() async {
    final shot = _current;
    if (!await deleteShots(context, [shot]) || !mounted) return;
    setState(() {
      _items.remove(shot);
      if (_index >= _items.length) _index = _items.length - 1;
    });
    if (_items.isEmpty) Navigator.of(context).pop();
  }

  void _info() {
    final s = _current;
    showAppSheet<void>(context, (context) {
      final t = context.tokens;
      Widget row(IconData i, String k, String v) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconBadge(i, color: context.highlight, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(k, style: context.text.bodySmall),
                  const SizedBox(height: 2),
                  SelectableText(v.isEmpty ? '—' : v, style: context.text.titleSmall),
                ]),
              ),
            ]),
          );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeading(title: s.app, accent: 'details'),
          Row(children: [
            Expanded(child: row(Icons.apps_rounded, 'App · ${appSourceText(s.appSource)}', s.app)),
            PillButton(
              label: 'Change',
              style: PillStyle.soft,
              height: 40,
              expand: false,
              onTap: () {
                Navigator.pop(context);
                setAppFor(this.context, [s]);
              },
            ),
          ]),
          row(Icons.event_rounded, 'Taken', '${longDate(s.date)} at ${timeOfDay(s.date)}'),
          row(Icons.aspect_ratio_rounded, 'Size',
              '${s.width} × ${s.height}  ·  ${formatBytes(s.size)}'),
          row(Icons.insert_drive_file_outlined, 'File', s.name),
          row(Icons.folder_outlined, 'Folder', s.folder),
          Divider(color: t.border, height: 24),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const ColoredBox(color: Colors.black);
    final lib = LibraryScope.of(context);
    final shot = _current;
    final favorite = lib.isFavorite(shot);
    final pad = MediaQuery.paddingOf(context);
    final fade = (1 - (_drag.abs() / 300)).clamp(0.0, 1.0);
    final showChrome = _chrome && _drag == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: fade),
        body: Stack(children: [
          GestureDetector(
            onVerticalDragUpdate: _zoomed ? null : (d) => setState(() => _drag += d.delta.dy),
            onVerticalDragEnd: _zoomed
                ? null
                : (d) {
                    if (_drag.abs() > 110 || d.velocity.pixelsPerSecond.dy.abs() > 900) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _drag = 0);
                    }
                  },
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: Transform.scale(
                scale: 1 - (_drag.abs() / 2400).clamp(0.0, 0.12),
                child: PageView.builder(
                  controller: _pages,
                  physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                  itemCount: _items.length,
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    _zoomed = false;
                  }),
                  itemBuilder: (context, i) {
                    final s = _items[i];
                    return _ZoomableShot(
                      key: ValueKey(s.id),
                      shot: s,
                      heroTag: i == _heroIndex ? '${widget.heroPrefix}-${s.id}' : 'viewer-${s.id}',
                      topInset: pad.top + 72,
                      bottomInset: pad.bottom + 150,
                      onTap: () => setState(() => _chrome = !_chrome),
                      onZoomChanged: (z) {
                        if (z != _zoomed) setState(() => _zoomed = z);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: pad.top + 10,
            left: 16,
            right: 16,
            child: _Fade(
              visible: showChrome,
              child: Row(children: [
                GlassButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                Glass(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text('${_index + 1} / ${_items.length}',
                      style: context.text.labelMedium?.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                GlassButton(icon: Icons.info_outline_rounded, tooltip: 'Details', onTap: _info),
                const SizedBox(width: 10),
                GlassButton(
                  icon: Icons.open_in_new_rounded,
                  tooltip: 'Open with',
                  onTap: () => lib.openWith(shot),
                ),
              ]),
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
          ),
          // Caption + actions
          Positioned(
            left: 16,
            right: 16,
            bottom: pad.bottom + 20,
            child: _Fade(
              visible: showChrome,
              child: Glass(
                radius: 30,
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 10),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Row(
                      key: ValueKey(shot.id),
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                              color: colorFor(shot.app), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(shot.app,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(color: Colors.white)),
                        ),
                        Text('${shortDate(shot.date)}, ${timeOfDay(shot.date)}',
                            style: serifAccent(17, Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    _Action(
                      icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: 'Favorite',
                      color: favorite ? Brand.coral : Colors.white,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        lib.setFavorite([shot], !favorite);
                      },
                    ),
                    _Action(
                      icon: Icons.photo_album_outlined,
                      label: 'Album',
                      onTap: () => addToAlbum(context, [shot]),
                    ),
                    _Action(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      onTap: () => lib.share([shot]),
                    ),
                    _Action(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      onTap: _delete,
                    ),
                  ]),
                ]),
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(
                begin: 0.3, end: 0, delay: 250.ms, duration: 450.ms, curve: Curves.easeOutCubic),
          ),
        ]),
      ),
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
      );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.color = Colors.white});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(label,
                    style: context.text.labelMedium
                        ?.copyWith(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.75))),
              ]),
            ),
          ),
        ),
      );
}

class _ZoomableShot extends StatefulWidget {
  const _ZoomableShot({
    super.key,
    required this.shot,
    required this.heroTag,
    required this.topInset,
    required this.bottomInset,
    required this.onTap,
    required this.onZoomChanged,
  });

  final Shot shot;
  final String heroTag;
  final double topInset;
  final double bottomInset;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableShot> createState() => _ZoomableShotState();
}

class _ZoomableShotState extends State<_ZoomableShot> {
  final _transform = TransformationController();
  Offset _tapAt = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(() {
      final z = _transform.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) {
        _zoomed = z;
        widget.onZoomChanged(z);
      }
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_zoomed) {
      _transform.value = Matrix4.identity();
    } else {
      const s = 2.5;
      _transform.value = Matrix4.diagonal3Values(s, s, 1)
        ..setTranslationRaw(-_tapAt.dx * (s - 1), -_tapAt.dy * (s - 1), 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shot = widget.shot;
    final full = shot.asset != null
        ? Image.asset(shot.asset!, fit: BoxFit.contain, gaplessPlayback: true)
        : shot.path.isEmpty
            ? const SizedBox.shrink()
            : Image.file(
                File(shot.path),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              );
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (d) => _tapAt = d.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 6,
        child: SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, widget.topInset, 14, widget.bottomInset),
            child: Center(
              child: AspectRatio(
                aspectRatio: shot.aspect,
                child: Hero(
                  tag: widget.heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(fit: StackFit.expand, children: [
                      ShotThumb(shot, fit: BoxFit.contain),
                      full,
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

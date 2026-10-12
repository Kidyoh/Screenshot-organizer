import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../data/shot.dart';
import 'actions.dart';
import 'scope.dart';

/// Full-screen, swipeable, pinch-to-zoom screenshot viewer.
class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key, required this.shots, required this.initialIndex});
  final List<Shot> shots;
  final int initialIndex;

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final List<Shot> _items = [...widget.shots];
  late int _index = widget.initialIndex.clamp(0, _items.length - 1);
  late final PageController _pages = PageController(initialPage: _index);
  bool _chrome = true;
  bool _zoomed = false;

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

  void _showInfo() {
    final s = _current;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(Icons.apps, 'App', s.app),
              _InfoRow(Icons.event, 'Taken',
                  '${shortDate(s.date)} at ${timeOfDay(s.date)}'),
              _InfoRow(Icons.aspect_ratio, 'Size',
                  '${s.width} × ${s.height} · ${formatBytes(s.size)}'),
              _InfoRow(Icons.insert_drive_file_outlined, 'File', s.name),
              _InfoRow(Icons.folder_outlined, 'Folder', s.folder),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const Scaffold(backgroundColor: Colors.black);
    final lib = LibraryScope.of(context);
    final shot = _current;
    final favorite = lib.isFavorite(shot);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: _chrome
            ? AppBar(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shot.app, style: const TextStyle(fontSize: 17)),
                    Text('${shortDate(shot.date)} · ${timeOfDay(shot.date)}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Details',
                    icon: const Icon(Icons.info_outline),
                    onPressed: _showInfo,
                  ),
                  IconButton(
                    tooltip: 'Open with…',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => lib.openWith(shot),
                  ),
                ],
              )
            : null,
        body: PageView.builder(
          controller: _pages,
          physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
          itemCount: _items.length,
          onPageChanged: (i) => setState(() {
            _index = i;
            _zoomed = false;
          }),
          itemBuilder: (context, i) => _ZoomableShot(
            key: ValueKey(_items[i].id),
            shot: _items[i],
            onTap: () => setState(() => _chrome = !_chrome),
            onZoomChanged: (z) {
              if (z != _zoomed) setState(() => _zoomed = z);
            },
          ),
        ),
        bottomNavigationBar: _chrome
            ? Container(
                color: Colors.black54,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BarButton(
                          icon: favorite ? Icons.favorite : Icons.favorite_border,
                          label: 'Favorite',
                          onTap: () => lib.setFavorite([shot], !favorite),
                        ),
                        _BarButton(
                          icon: Icons.library_add_outlined,
                          label: 'Album',
                          onTap: () => addToAlbum(context, [shot]),
                        ),
                        _BarButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () => lib.share([shot]),
                        ),
                        _BarButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          onTap: _delete,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(icon),
        title: Text(label),
        subtitle: SelectableText(value.isEmpty ? '—' : value),
      );
}

class _ZoomableShot extends StatefulWidget {
  const _ZoomableShot({
    super.key,
    required this.shot,
    required this.onTap,
    required this.onZoomChanged,
  });

  final Shot shot;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableShot> createState() => _ZoomableShotState();
}

class _ZoomableShotState extends State<_ZoomableShot> {
  final _transform = TransformationController();
  Offset _doubleTapAt = Offset.zero;
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
      final p = _doubleTapAt;
      _transform.value = Matrix4.diagonal3Values(s, s, 1)
        ..setTranslationRaw(-p.dx * (s - 1), -p.dy * (s - 1), 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shot = widget.shot;
    final fallback = Image(
      image: AssetEntityImageProvider(
        shot.entity,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize(1080, 2400),
      ),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined,
          color: Colors.white54, size: 48),
    );
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 6,
        child: SizedBox.expand(
          child: shot.path.isEmpty
              ? fallback
              : Image.file(
                  File(shot.path),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

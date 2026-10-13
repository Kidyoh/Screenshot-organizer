import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/routes.dart';
import '../../data/shot.dart';
import '../actions.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/pressable.dart';
import '../widgets/shots.dart';
import 'group_screen.dart';

enum _Verdict { delete, keep, favorite }

typedef _Step = ({Shot shot, _Verdict verdict, bool wasFavorite});

/// Opens a Swipe to clean session over [shots], in the order given.
void openSwipe(
  BuildContext context,
  List<Shot> shots, {
  String title = 'Swipe to clean',
}) {
  if (shots.isEmpty) {
    showSnack(
      context,
      'Nothing to go through here',
      icon: Icons.check_circle_rounded,
    );
    return;
  }
  Navigator.of(context)
      .push(pageRoute((_) => SwipeScreen(shots: shots, title: title)));
}

/// Tinder-style triage: swipe left to delete, right to keep, up to favorite.
/// Deletions are collected and done together at the end, so Android only
/// asks once.
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key, required this.shots, required this.title});

  final List<Shot> shots;
  final String title;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  late final List<Shot> _queue = [...widget.shots];
  final List<_Step> _history = [];
  final List<Shot> _marked = [];
  late final AnimationController _anim = AnimationController(vsync: this)
    ..addListener(() => setState(() {}));

  int _index = 0;
  bool _finished = false;
  bool _flying = false;
  bool _armed = false;
  Offset _drag = Offset.zero;
  Animation<Offset>? _flight;
  Size _area = const Size(300, 600);

  Offset get _offset => _flight?.value ?? _drag;
  bool get _done => _finished || _index >= _queue.length;
  int get _markedSize => _marked.fold(0, (n, s) => n + s.size);

  double get _threshold => _area.width * 0.28;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNext();
  }

  void _precacheNext() {
    for (var i = _index; i < math.min(_index + 2, _queue.length); i++) {
      precacheImage(largeProvider(_queue[i]), context).ignore();
    }
  }

  // ---- Gestures ----

  void _onPanUpdate(DragUpdateDetails d) {
    if (_flying) return;
    setState(() => _drag += d.delta);
    final armed = _verdictFor(_drag, Offset.zero) != null;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_flying) return;
    final verdict = _verdictFor(_drag, d.velocity.pixelsPerSecond);
    _armed = false;
    if (verdict == null) {
      _animateTo(
        Offset.zero,
        const Duration(milliseconds: 380),
        Curves.easeOutBack,
      ).then((_) => _drag = Offset.zero);
    } else {
      _fling(verdict);
    }
  }

  _Verdict? _verdictFor(Offset o, Offset velocity) {
    final up = o.dy < -_area.height * 0.2 && o.dy.abs() > o.dx.abs();
    if (up) return _Verdict.favorite;
    if (o.dx > _threshold || velocity.dx > 900) return _Verdict.keep;
    if (o.dx < -_threshold || velocity.dx < -900) return _Verdict.delete;
    return null;
  }

  Future<void> _animateTo(Offset target, Duration duration, Curve curve) {
    _flight = Tween(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: curve));
    _anim.duration = duration;
    return _anim.forward(from: 0).then((_) {
      _flight = null;
      _drag = target;
    });
  }

  Future<void> _fling(_Verdict verdict) async {
    if (_flying || _done) return;
    _flying = true;
    final w = _area.width, h = _area.height;
    final target = switch (verdict) {
      _Verdict.delete => Offset(-w * 1.5, _offset.dy + 60),
      _Verdict.keep => Offset(w * 1.5, _offset.dy + 60),
      _Verdict.favorite => Offset(_offset.dx, -h * 1.4),
    };
    await _animateTo(target, const Duration(milliseconds: 240), Curves.easeIn);
    _commit(verdict);
    setState(() {
      _drag = Offset.zero;
      _flying = false;
    });
  }

  void _commit(_Verdict verdict) {
    final lib = LibraryScope.read(context);
    final shot = _queue[_index];
    final wasFavorite = lib.isFavorite(shot);
    switch (verdict) {
      case _Verdict.delete:
        _marked.add(shot);
        HapticFeedback.mediumImpact();
      case _Verdict.keep:
        lib.setReviewed(shot, true);
        HapticFeedback.lightImpact();
      case _Verdict.favorite:
        lib.setFavorite([shot], true);
        lib.setReviewed(shot, true);
        HapticFeedback.lightImpact();
    }
    _history.add((shot: shot, verdict: verdict, wasFavorite: wasFavorite));
    _index++;
    _precacheNext();
  }

  void _undo() {
    if (_history.isEmpty || _flying) return;
    final lib = LibraryScope.read(context);
    final step = _history.removeLast();
    switch (step.verdict) {
      case _Verdict.delete:
        _marked.remove(step.shot);
      case _Verdict.keep:
        lib.setReviewed(step.shot, false);
      case _Verdict.favorite:
        lib.setReviewed(step.shot, false);
        if (!step.wasFavorite) lib.setFavorite([step.shot], false);
    }
    HapticFeedback.selectionClick();
    setState(() {
      _finished = false;
      _index--;
      _drag = Offset.zero;
    });
  }

  // ---- Ending ----

  Future<void> _deleteMarked() async {
    if (await deleteShots(context, [..._marked]) && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _reviewMarked() async {
    final ids = _marked.map((s) => s.id).toSet();
    await Navigator.of(context).push(
      pageRoute(
        (_) => GroupScreen(
          title: 'Marked',
          overline: 'Review',
          sections: (lib) => [
            if (lib.resolve(ids).isNotEmpty)
              Section('Marked to delete', lib.resolve(ids)),
          ],
          initialSelection: ids,
          hint: 'Untick any you want to keep, then tap Delete.',
          emptyMessage: 'Nothing left to delete.',
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmLeave() async {
    if (_marked.isEmpty) return true;
    return confirm(
      context,
      title: 'Leave',
      accent: 'without deleting?',
      message:
          '${formatCount(_marked.length, 'marked screenshot')} will stay on your phone.',
      action: 'Leave',
      danger: false,
    );
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final t = context.tokens;
    return PopScope(
      canPop: _marked.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          _marked.clear();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.fromLTRB(0, pad.top + 10, 0, pad.bottom + 18),
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: _done
                    ? _summary(context)
                    : LayoutBuilder(
                        builder: (context, c) {
                          _area = Size(c.maxWidth, c.maxHeight);
                          return _stack(context, c);
                        },
                      ),
              ),
              if (!_done) ...[
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _history.isEmpty && _offset == Offset.zero ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 14),
                    child: Text(
                      'Left to delete  ·  Right to keep  ·  Up to favorite',
                      style: context.text.bodySmall?.copyWith(color: t.muted),
                    ),
                  ),
                ),
                _controls(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final t = context.tokens;
    final total = _queue.length;
    final seen = math.min(_index, total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.page, 0, Insets.page, 14),
      child: Column(
        children: [
          Row(
            children: [
              CircleButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                onTap: () async {
                  if (await _confirmLeave() && mounted) {
                    _marked.clear();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(widget.title),
                    const SizedBox(height: 2),
                    Text(
                      _done ? (_index >= total ? 'All done' : 'Summary') : '${seen + 1} of $total',
                      style: context.text.titleMedium,
                    ),
                  ],
                ),
              ),
              if (!_done && _marked.isNotEmpty)
                PillButton(
                  label: '${_marked.length} · Finish',
                  style: PillStyle.ink,
                  height: 42,
                  expand: false,
                  onTap: () => setState(() => _finished = true),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total == 0 ? 1 : (_done ? 1 : seen / total),
              minHeight: 6,
              backgroundColor: t.track,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stack(BuildContext context, BoxConstraints c) {
    // Card fills the area at a screenshot-like aspect.
    final cardW = math.min(
      c.maxWidth - Insets.page * 2,
      (c.maxHeight - 30) * 0.5,
    );
    final cardH = math.min(c.maxHeight - 30, cardW * 2.05);
    final progress = (_offset.distance / _threshold).clamp(0.0, 1.0);
    final cards = <Widget>[];
    for (var depth = 2; depth >= 0; depth--) {
      final i = _index + depth;
      if (i >= _queue.length) continue;
      final shot = _queue[i];
      if (depth == 0) {
        cards.add(
          Transform.translate(
            offset: _offset,
            child: Transform.rotate(
              angle: (_offset.dx / c.maxWidth) * 0.32,
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: _SwipeCard(
                  key: ValueKey(shot.id),
                  shot: shot,
                  width: cardW,
                  height: cardH,
                  offset: _offset,
                  threshold: _threshold,
                  verticalThreshold: c.maxHeight * 0.2,
                ),
              ),
            ),
          ),
        );
      } else {
        // Cards behind grow into place as the top one moves away.
        final d = depth - (depth == 1 ? progress : progress * 0.5);
        cards.add(
          Transform.translate(
            offset: Offset(0, 22 * d),
            child: Transform.scale(
              scale: 1 - 0.05 * d,
              alignment: Alignment.topCenter,
              child: _SwipeCard(
                key: ValueKey(shot.id),
                shot: shot,
                width: cardW,
                height: cardH,
                offset: Offset.zero,
                threshold: _threshold,
                verticalThreshold: 1,
                dim: 0.06 * d,
              ),
            ),
          ),
        );
      }
    }
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: cards,
    );
  }

  Widget _controls(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundAction(
          icon: Icons.undo_rounded,
          label: 'Undo',
          size: 52,
          background: t.card,
          foreground: _history.isEmpty ? t.faint : t.ink,
          onTap: _history.isEmpty ? null : _undo,
        ),
        const SizedBox(width: 18),
        _RoundAction(
          icon: Icons.close_rounded,
          label: 'Delete',
          size: 72,
          background: Brand.coral,
          foreground: Colors.white,
          onTap: () => _fling(_Verdict.delete),
        ),
        const SizedBox(width: 18),
        _RoundAction(
          icon: Icons.favorite_rounded,
          label: 'Favorite',
          size: 58,
          background: t.card,
          foreground: context.highlight,
          onTap: () => _fling(_Verdict.favorite),
        ),
        const SizedBox(width: 18),
        _RoundAction(
          icon: Icons.check_rounded,
          label: 'Keep',
          size: 72,
          background: Brand.mint,
          foreground: Colors.white,
          onTap: () => _fling(_Verdict.keep),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context) {
    final t = context.tokens;
    final kept = _history.where((s) => s.verdict != _Verdict.delete).length;
    if (_marked.isEmpty) {
      return EmptyState(
        icon: Icons.check_rounded,
        title: 'All done',
        message: kept == 0
            ? 'Nothing marked to delete.'
            : 'You kept all ${formatCount(kept, 'screenshot')}. Nothing to delete.',
        bottomPadding: 40,
        action: PillButton(
          label: 'Done',
          expand: false,
          onTap: () => Navigator.of(context).pop(),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Insets.page + 2, 20, Insets.page, 0),
      child:
          Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: FannedStack(
                      shots: _marked.reversed.toList(),
                      cardWidth: 82,
                      spread: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${_marked.length} '),
                        TextSpan(
                          text: 'marked.',
                          style: serifAccent(44, Brand.coral),
                        ),
                      ],
                    ),
                    style: context.text.displaySmall?.copyWith(fontSize: 44),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatBytes(_markedSize)} to free'
                    '${kept > 0 ? ' · you kept ${formatCount(kept, 'screenshot')}' : ''}',
                    style: context.text.bodyLarge?.copyWith(color: t.muted),
                  ),
                  const SizedBox(height: 28),
                  PillButton(
                    label:
                        'Delete ${formatCount(_marked.length, 'screenshot')}',
                    icon: Icons.delete_outline_rounded,
                    style: PillStyle.danger,
                    onTap: _deleteMarked,
                  ),
                  const SizedBox(height: 10),
                  PillButton(
                    label: 'Review first',
                    style: PillStyle.soft,
                    onTap: _reviewMarked,
                  ),
                  const SizedBox(height: 10),
                  PillButton(
                    label: 'Keep going',
                    style: PillStyle.soft,
                    onTap: _index < _queue.length
                        ? () => setState(() => _finished = false)
                        : null,
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    super.key,
    required this.shot,
    required this.width,
    required this.height,
    required this.offset,
    required this.threshold,
    required this.verticalThreshold,
    this.dim = 0,
  });

  final Shot shot;
  final double width;
  final double height;
  final Offset offset;
  final double threshold;
  final double verticalThreshold;
  final double dim;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final up = offset.dy < 0 && offset.dy.abs() > offset.dx.abs();
    final keep = up ? 0.0 : (offset.dx / threshold).clamp(0.0, 1.0);
    final delete = up ? 0.0 : (-offset.dx / threshold).clamp(0.0, 1.0);
    final favorite = up
        ? (-offset.dy / verticalThreshold).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.45 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: t.track),
            Image(
              image: largeProvider(shot),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => ShotThumb(shot),
            ),
            if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Row(
                children: [
                  Flexible(
                    child: Glass(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorFor(shot.app),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              shot.app,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Glass(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      shortDate(shot.date),
                      maxLines: 1,
                      style: context.text.labelMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              top: 22,
              right: width * 0.4,
              child: _Stamp(
                label: 'Keep',
                icon: Icons.check_rounded,
                color: Brand.mint,
                angle: -0.2,
                opacity: keep,
              ),
            ),
            Positioned(
              right: 18,
              top: 22,
              left: width * 0.4,
              child: _Stamp(
                label: 'Delete',
                icon: Icons.close_rounded,
                color: Brand.coral,
                angle: 0.2,
                opacity: delete,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: height * 0.32,
              child: Center(
                child: _Stamp(
                  label: 'Favorite',
                  icon: Icons.favorite_rounded,
                  color: context.highlight,
                  angle: 0,
                  opacity: favorite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.icon,
    required this.color,
    required this.angle,
    required this.opacity,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double angle;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 0.85 + 0.15 * opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: context.text.labelLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 17,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.size,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double size;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Pressable(
          onTap: onTap,
          scale: 0.88,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: context.tokens.raised,
            ),
            child: Icon(icon, color: foreground, size: size * 0.44),
          ),
        ),
      ),
    );
  }
}

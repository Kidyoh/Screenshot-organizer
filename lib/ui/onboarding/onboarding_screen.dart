import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';
import 'arts.dart';

class _Page {
  const _Page(this.lead, this.accent, this.body, this.art);
  final String lead;
  final String accent;
  final String body;
  final Widget Function(bool active) art;
}

final _pages = [
  _Page('Screenshots,', 'sorted.',
      'SnapSort reads your Screenshots folder and tidies it up for you. No AI, no account.',
      (a) => FanArt(active: a)),
  _Page('Grouped by', 'app.',
      'WhatsApp chats, receipts, maps and memes each get their own pile, straight from the file names.',
      (a) => SortArt(active: a)),
  _Page('Clear the', 'clutter.',
      'Find exact duplicates, old screenshots and the biggest files, and free up space in a tap.',
      (a) => CleanArt(active: a)),
];

/// First-run walkthrough that ends by asking for photo access.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _asking = false;

  bool get _last => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_last) {
      _controller.nextPage(duration: const Duration(milliseconds: 650), curve: Curves.easeOutCubic);
      return;
    }
    setState(() => _asking = true);
    await LibraryScope.read(context).checkPermission(ask: true);
    if (mounted) setState(() => _asking = false);
  }

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final t = context.tokens;
    final pad = MediaQuery.paddingOf(context);
    final denied = lib.permission == PermissionState.denied ||
        lib.permission == PermissionState.restricted;

    return Scaffold(
      body: Column(children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _index = i);
            },
            itemBuilder: (context, i) {
              final p = _pages[i];
              return Padding(
                padding: EdgeInsets.fromLTRB(28, pad.top + 24, 28, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('snapsort', style: serifAccent(24, t.ink)),
                  Expanded(child: Center(child: p.art(i == _index))),
                  PageTitle(lead: p.lead, accent: p.accent, size: 44),
                  const SizedBox(height: 14),
                  Text(p.body, style: context.text.bodyLarge?.copyWith(color: t.muted)),
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(28, 22, 28, pad.bottom + 22),
          child: Column(children: [
            if (_last && denied)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Photo access is off. SnapSort needs it to see your screenshots.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: Brand.coral),
                ),
              ),
            Row(children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? t.ink : t.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const Spacer(),
              PillButton(
                label: _last
                    ? (denied ? 'Try again' : 'Allow access')
                    : 'Next',
                icon: _last ? Icons.photo_library_rounded : Icons.arrow_forward_rounded,
                expand: false,
                busy: _asking,
                onTap: _next,
              ),
            ]),
            if (_last && denied)
              TextButton(
                onPressed: PhotoManager.openSetting,
                child: Text('Open Settings',
                    style: context.text.labelLarge?.copyWith(color: context.highlight)),
              ),
          ]),
        ),
      ]),
    );
  }
}

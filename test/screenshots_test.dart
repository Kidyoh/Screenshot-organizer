// Renders the real screens with demo data to docs/screenshots/*.png.
//   flutter test --dart-define=SCREENSHOTS=true test/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapsort/app/prefs.dart';
import 'package:snapsort/data/demo.dart';
import 'package:snapsort/data/library.dart';
import 'package:snapsort/main.dart';
import 'package:snapsort/ui/onboarding/onboarding_screen.dart';
import 'package:snapsort/ui/screens/shell.dart';
import 'package:snapsort/ui/screens/swipe_screen.dart';
import 'package:snapsort/ui/widgets/shots.dart';

const enabled = bool.fromEnvironment('SCREENSHOTS');
final _root = GlobalKey();

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(rootBundle.load(f));
    }
    await loader.load();
  }

  await load('PlusJakartaSans', [
    for (final w in [400, 500, 600, 700, 800]) 'assets/fonts/PlusJakartaSans-w$w.ttf',
  ]);
  await load('InstrumentSerif', [
    'assets/fonts/InstrumentSerif_400Regular.ttf',
    'assets/fonts/InstrumentSerif_400Regular_Italic.ttf',
  ]);
  final icons = File(
      '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
  await loader.load();
}

Future<void> _snap(WidgetTester tester, String name) async {
  debugDisableShadows = false;
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  final boundary = _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('docs/screenshots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

/// Demo data on a phone without Usage access, so untagged screenshots stay unknown.
class _NoUsageDemo extends DemoMediaChannel {
  _NoUsageDemo({super.now});
  @override
  Future<bool> usageAccess() async => false;
}

Future<Library> _launch(WidgetTester tester,
    {Widget? home, ThemeMode mode = ThemeMode.light, bool usage = true}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
  addTearDown(tester.view.reset);
  final lib = Library(
    channel: usage
        ? DemoMediaChannel(now: DateTime.now().subtract(const Duration(minutes: 20)))
        : _NoUsageDemo(now: DateTime.now().subtract(const Duration(minutes: 20))),
    permission: ({required bool ask}) async => PermissionState.authorized,
  );
  await lib.start();
  final prefs = Prefs()..themeMode = mode;
  await tester.pumpWidget(RepaintBoundary(
    key: _root,
    child: SnapSortApp(library: lib, prefs: prefs, home: home),
  ));
  // Decode every demo image up front so tiles aren't blank.
  await tester.runAsync(() async {
    final ctx = _root.currentContext!;
    for (final a in demoAssets) {
      await precacheImage(AssetImage(demoAssetPath(a)), ctx);
      await precacheImage(ResizeImage(AssetImage(demoAssetPath(a)), width: 360), ctx);
    }
  });
  await tester.pump();
  return lib;
}

void main() {
  setUpAll(_loadFonts);

  setUp(() => SharedPreferences.setMockInitialValues({'usagePromptShown': true}));

  testWidgets('onboarding', (tester) async {
    await _launch(tester, home: const OnboardingScreen());
    await _snap(tester, 'onboarding-1');
    await tester.tap(find.text('Next'));
    await _snap(tester, 'onboarding-2');
    await tester.tap(find.text('Next'));
    await _snap(tester, 'onboarding-3');
  }, skip: !enabled);

  testWidgets('tabs', (tester) async {
    final lib = await _launch(tester, home: const Shell());
    lib.setFavorite(lib.shots.take(5), true);
    lib.addToAlbum('Receipts', lib.shots.where((s) => s.app == 'Bank'));
    lib.addToAlbum('Travel', lib.shots.where((s) => s.app == 'Gmail' || s.app == 'Maps'));
    lib.addToAlbum('Recipes', lib.shots.where((s) => s.app == 'Chrome').take(2));
    await _snap(tester, 'timeline');
    await tester.tap(find.textContaining('WhatsApp ', findRichText: true).first);
    await _snap(tester, 'timeline-filter');
    await tester.tap(find.text('All', findRichText: true).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -620));
    await _snap(tester, 'timeline-grid');

    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, 620));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.bySemanticsLabel('Apps'));
    await _snap(tester, 'apps');
    await tester.tap(find.bySemanticsLabel('Albums'));
    await _snap(tester, 'albums');
    await tester.tap(find.bySemanticsLabel('Clean up'));
    await tester.runAsync(lib.scanDuplicates);
    await _snap(tester, 'cleanup');

    await tester.tap(find.bySemanticsLabel('Apps'));
    await tester.pump();
    await tester.tap(find.text('WhatsApp').first);
    await _snap(tester, 'app-page');
  }, skip: !enabled);

  testWidgets('selecting', (tester) async {
    await _launch(tester, home: const Shell());
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -620));
    await tester.pump(const Duration(seconds: 1));
    final tiles = find.byType(ShotTile);
    await tester.longPress(tiles.at(1));
    await tester.pump();
    await tester.tap(tiles.at(2));
    await tester.tap(tiles.at(4));
    await _snap(tester, 'selecting');
  }, skip: !enabled);

  testWidgets('viewer', (tester) async {
    await _launch(tester, home: const Shell());
    await tester.tap(find.textContaining('Today,').first);
    await _snap(tester, 'viewer');
  }, skip: !enabled);

  testWidgets('dark', (tester) async {
    await _launch(tester, home: const Shell(), mode: ThemeMode.dark);
    await _snap(tester, 'timeline-dark');
    await tester.tap(find.bySemanticsLabel('Clean up'));
    await _snap(tester, 'cleanup-dark');
  }, skip: !enabled);

  testWidgets('swipe', (tester) async {
    final lib = await _launch(tester, home: const Shell());
    await tester.tap(find.bySemanticsLabel('Clean up'));
    await _snap(tester, 'cleanup');
    await tester.pumpWidget(RepaintBoundary(
      key: _root,
      child: SnapSortApp(
        library: lib,
        prefs: Prefs()..themeMode = ThemeMode.light,
        home: SwipeScreen(shots: lib.unreviewed.reversed.toList(), title: 'Swipe to clean'),
      ),
    ));
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    await tester.tap(find.bySemanticsLabel('Keep'));
    await settle();
    await tester.tap(find.bySemanticsLabel('Delete'));
    await settle();
    final g = await tester.startGesture(tester.getCenter(find.byType(SwipeScreen)));
    await g.moveBy(const Offset(-40, 0));
    await g.moveBy(const Offset(-80, 6));
    await tester.pump();
    await _snap(tester, 'swipe');
    await g.moveBy(const Offset(-200, 10));
    await g.up();
    await settle();
    await tester.tap(find.textContaining('Finish'));
    await _snap(tester, 'swipe-summary');
  }, skip: !enabled);

  testWidgets('usage access', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _launch(tester, home: const Shell(), usage: false);
    await _snap(tester, 'usage-prompt');
    await tester.tap(find.text('Not now'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.bySemanticsLabel('Apps'));
    await _snap(tester, 'usage-card');
  }, skip: !enabled);
}

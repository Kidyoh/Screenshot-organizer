import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapsort/app/prefs.dart';
import 'package:snapsort/data/library.dart';
import 'package:snapsort/data/media_channel.dart';
import 'package:snapsort/data/shot.dart';
import 'package:snapsort/main.dart';
import 'package:snapsort/ui/screens/shell.dart';
import 'package:snapsort/ui/screens/swipe_screen.dart';

/// Stands in for the native side with a handful of made-up screenshots.
class FakeMedia extends MediaChannel {
  final trashed = <int>{};

  @override
  Future<int> sdkInt() async => 34;

  @override
  Future<List<Shot>> queryScreenshots() async {
    final now = DateTime.now();
    Map<String, Object> m(int id, String name, Duration age, int size,
            [String folder = 'Pictures/Screenshots/']) =>
        {
          'id': id,
          'name': name,
          'date': now.subtract(age).millisecondsSinceEpoch,
          'size': size,
          'width': 1080,
          'height': 2400,
          'folder': folder,
          'path': '/nonexistent/$name',
        };
    return [
      m(1, 'Screenshot_20260101-101010_WhatsApp.jpg', Duration.zero, 500000),
      m(2, 'Screenshot_20260101-101011_WhatsApp.jpg', const Duration(days: 1), 500000),
      m(3, 'Screenshot_2026-01-01-10-10-12-123_com.android.chrome.jpg', const Duration(days: 3), 900000),
      m(4, 'Screenshot_20250101-101013.png', const Duration(days: 200), 3000000),
      m(5, 'Screenshot_20250101-101014.png', const Duration(days: 400), 1200000,
          'DCIM/Screenshots/Instagram/'),
      m(6, 'Screenshot_20250101-101015_Chrome.png', const Duration(days: 40), 700000),
    ].where((e) => !trashed.contains(e['id'])).map(Shot.fromMap).toList();
  }

  @override
  Future<Map<String, String>> appLabels(List<String> packages) async =>
      {'com.android.chrome': 'Chrome', 'com.tinder': 'Tinder'};

  @override
  Future<Map<String, String>> hashLabels() async => const {};

  /// Pretend usage history: screenshot id -> package open at that moment.
  Map<int, String> usage = const {};
  bool access = false;

  @override
  Future<bool> usageAccess() async => access;

  @override
  Future<void> openUsageAccess() async {}

  @override
  Future<Map<int, String>> appsAt(Map<int, int> times) async =>
      {for (final id in times.keys) if (usage[id] != null) id: usage[id]!};

  // Shots 1 and 2 are identical files.
  @override
  Future<Map<int, String>> md5(List<int> ids) async =>
      {for (final id in ids) id: id <= 2 ? 'same' : 'h$id'};

  @override
  Future<bool> trash(List<int> ids) async {
    trashed.addAll(ids);
    return true;
  }

  @override
  Future<void> share(List<int> ids) async {}

  @override
  Future<void> openWith(int id) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'usagePromptShown': true}));

  Future<Library> launch(WidgetTester tester, {FakeMedia? media}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final lib = Library(
      channel: media ?? FakeMedia(),
      permission: ({required bool ask}) async => PermissionState.authorized,
    );
    await lib.start();
    await tester.pumpWidget(SnapSortApp(library: lib, prefs: Prefs()));
    await tester.pumpAndSettle();
    return lib;
  }

  testWidgets('groups screenshots by app and opens the tabs', (tester) async {
    final lib = await launch(tester);
    expect(find.byType(Shell), findsOneWidget);
    expect(lib.shots, hasLength(6));
    expect({for (final g in lib.apps) g.name: g.shots.length},
        {'Chrome': 2, 'WhatsApp': 2, 'Instagram': 1, 'Other': 1});
    expect(find.textContaining('TODAY', findRichText: true), findsOneWidget);

    // Filter pill
    await tester.tap(find.text('Chrome  2', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(1)), findsNothing);
    expect(find.byKey(const ValueKey(3)), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text('2 screenshots · 977 KB'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Albums'));
    await tester.pumpAndSettle();
    expect(find.text('New album'), findsOneWidget);
  });

  testWidgets('select, add to a new album, then clean up duplicates', (tester) async {
    final lib = await launch(tester);

    await tester.longPress(find.byKey(const ValueKey(1)));
    await tester.pumpAndSettle();
    expect(find.textContaining('selected', findRichText: true).hitTestable(), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Album').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('New album'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Chats');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(lib.albumShots('Chats').map((s) => s.id), [1]);
    expect(find.textContaining('selected', findRichText: true).hitTestable(), findsNothing);

    await tester.tap(find.bySemanticsLabel('Clean up'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Scan'), 200, scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('1 extra copy you can let go'), findsOneWidget);
    await tester.tap(find.text('Review').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 ', findRichText: true), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Delete').hitTestable());
    await tester.pumpAndSettle();
    expect(lib.shots, hasLength(5));
    expect(find.text('All clear'), findsOneWidget);
  });

  testWidgets('viewer favourites and deletes', (tester) async {
    final lib = await launch(tester);
    await tester.dragUntilVisible(
        find.byKey(const ValueKey(3)), find.byType(CustomScrollView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(3)));
    await tester.pumpAndSettle();
    expect(find.text('Chrome'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Favorite').hitTestable());
    await tester.pumpAndSettle();
    expect(lib.favorites, {3});
    await tester.tap(find.bySemanticsLabel('Delete').hitTestable());
    await tester.pumpAndSettle();
    expect(lib.shots, hasLength(5));
    await tester.tap(find.byTooltip('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Folder'), findsOneWidget);
  });

  testWidgets('every tab lays out with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final lib = await launch(tester);
    lib.setFavorite(lib.shots.take(2), true);
    lib.createAlbum('A rather long album name for testing');
    for (final tab in ['Apps', 'Albums', 'Clean up', 'Timeline']) {
      await tester.tap(find.bySemanticsLabel(tab));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.bySemanticsLabel('Clean up'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Scan'), 200, scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review').first);
    await tester.pumpAndSettle();
  });

  testWidgets('swipe to clean: drag, buttons, undo, then delete the marked ones', (tester) async {
    final lib = await launch(tester);
    await tester.tap(find.bySemanticsLabel('Clean up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.byType(SwipeScreen), findsOneWidget);
    expect(find.text('1 of 6'), findsOneWidget);

    // Oldest first: 5, 4, 6, 3, 2, 1.
    await tester.dragFrom(tester.getCenter(find.byType(SwipeScreen)), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Keep').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Favorite').hitTestable());
    await tester.pumpAndSettle();
    expect(lib.favorites, {6});
    await tester.tap(find.bySemanticsLabel('Undo').hitTestable());
    await tester.pumpAndSettle();
    expect(lib.favorites, isEmpty);
    expect(find.text('3 of 6'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Delete').hitTestable());
    await tester.pumpAndSettle();
    expect(lib.reviewed, {4});

    await tester.tap(find.text('2 · Finish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('marked', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Delete 2 screenshots'));
    await tester.pumpAndSettle();
    expect(lib.shots.map((s) => s.id).toSet(), {1, 2, 3, 4});
    expect(find.byType(SwipeScreen), findsNothing);
    // The next session skips what was kept.
    expect(lib.unreviewed.map((s) => s.id), [3, 2, 1]);
  });

  testWidgets('untagged screenshots get their app from usage history; a manual choice wins',
      (tester) async {
    final media = FakeMedia()
      ..access = true
      // 4 has no app in its name; 1 does, so usage must not override it.
      ..usage = {4: 'com.tinder', 1: 'com.tinder'};
    final lib = await launch(tester, media: media);
    final byId = {for (final s in lib.shots) s.id: s};
    expect(byId[4]!.app, 'Tinder');
    expect(byId[4]!.appSource, AppSource.usage);
    expect(byId[1]!.app, 'WhatsApp');
    expect(byId[1]!.appSource, AppSource.fileName);
    expect(lib.unknownCount, 0);

    // Pick an app by hand from the selection dock.
    await tester.longPress(find.byKey(const ValueKey(1)));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Set app').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tinder').last);
    await tester.pumpAndSettle();
    expect(lib.byId(1)!.app, 'Tinder');
    expect(lib.byId(1)!.appSource, AppSource.manual);

    // Back to automatic.
    await lib.setApp([lib.byId(1)!], null);
    expect(lib.byId(1)!.app, 'WhatsApp');
  });

  testWidgets('without usage access, the Apps tab offers it for untagged screenshots',
      (tester) async {
    final lib = await launch(tester);
    expect(lib.unknownCount, 1);
    await tester.tap(find.bySemanticsLabel('Apps'));
    await tester.pumpAndSettle();
    expect(find.text('Find the app for 1 screenshot'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Find the app for 1 screenshot'), findsNothing);
  });

  testWidgets('asks once for usage access when screenshots are untagged', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final lib = await launch(tester);
    expect(find.textContaining('One more', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(lib.usagePromptShown, isTrue);
    // The gentler card on the Apps tab is still there.
    await tester.tap(find.bySemanticsLabel('Apps'));
    await tester.pumpAndSettle();
    expect(find.text('Find the app for 1 screenshot'), findsOneWidget);
  });
}

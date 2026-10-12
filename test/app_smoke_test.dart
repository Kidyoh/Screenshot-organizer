import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapsort/data/library.dart';
import 'package:snapsort/data/media_channel.dart';
import 'package:snapsort/data/shot.dart';
import 'package:snapsort/main.dart';

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
      {'com.android.chrome': 'Chrome'};

  @override
  Future<Map<String, String>> hashLabels() async => const {};

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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(Library, FakeMedia)> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final media = FakeMedia();
    final lib = Library(
      channel: media,
      permission: ({required bool ask}) async => PermissionState.authorized,
    );
    await lib.start();
    await tester.pumpWidget(SnapSortApp(library: lib));
    await tester.pumpAndSettle();
    return (lib, media);
  }

  testWidgets('groups screenshots by app', (tester) async {
    final (lib, _) = await launch(tester);
    expect(lib.shots, hasLength(6));
    expect({for (final g in lib.apps) g.name: g.shots.length},
        {'Chrome': 2, 'WhatsApp': 2, 'Instagram': 1, 'Other': 1});
    expect(find.text('SnapSort'), findsOneWidget);
    expect(find.textContaining('Today', findRichText: true), findsOneWidget);
    expect(find.textContaining('Yesterday', findRichText: true), findsOneWidget);
  });

  testWidgets('select, add to album, browse every tab', (tester) async {
    final (lib, _) = await launch(tester);

    // Filter chip
    await tester.tap(find.text('Chrome  2'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(1)), findsNothing);
    expect(find.byKey(const ValueKey(3)), findsOneWidget);
    await tester.tap(find.text('All  6'));
    await tester.pumpAndSettle();

    // Long-press to select, then add to a new album
    await tester.longPress(find.byKey(const ValueKey(1)));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to album'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New album'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Chats');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(lib.albumShots('Chats').map((s) => s.id), [1]);

    // Apps tab -> open an app
    await tester.tap(find.text('Apps').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 screenshots'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Albums tab
    await tester.tap(find.text('Albums').last);
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsOneWidget);
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Clean up tab: duplicates
    await tester.tap(find.text('Clean up').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 extra copy'), findsOneWidget);
    await tester.tap(find.text('Review').first);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(lib.shots, hasLength(5));
    expect(find.text('All clear'), findsOneWidget);
  });

  testWidgets('viewer opens, favourites and deletes', (tester) async {
    final (lib, _) = await launch(tester);
    await tester.tap(find.byKey(const ValueKey(3)));
    await tester.pumpAndSettle();
    expect(find.text('Chrome'), findsWidgets);
    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();
    expect(lib.favorites, {3});
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(lib.shots, hasLength(5));
    await tester.tap(find.byTooltip('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Folder'), findsOneWidget);
  });
}

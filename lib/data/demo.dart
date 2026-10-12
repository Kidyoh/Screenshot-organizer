import 'dart:math';

import 'media_channel.dart';
import 'shot.dart';

/// Sample screenshots bundled in assets/demo, for `--dart-define=DEMO=true`
/// (store screenshots, trying the app on an emulator) and onboarding art.
const demoAssets = [
  'Screenshot_20261012-091522_WhatsApp',
  'Screenshot_20261011-201244_WhatsApp',
  'Screenshot_20261010-143010_Chrome',
  'Screenshot_20261009-190533_Chrome',
  'Screenshot_20261008-081210_Maps',
  'Screenshot_20261007-221804_Instagram',
  'Screenshot_20261006-171932_Spotify',
  'Screenshot_20261005-110245_Bank',
  'Screenshot_20261003-063015_Gmail',
  'Screenshot_20261002-213355_X',
  'Screenshot_20260928-090102_Calendar',
  'Screenshot_20260924-184420_Keep',
  'Screenshot_20260915-120931',
];

String demoAssetPath(String name) => 'assets/demo/$name.jpg';

/// A fake media store filled with the demo screenshots, spread over the last
/// few months so every screen has something to show.
class DemoMediaChannel extends MediaChannel {
  DemoMediaChannel({DateTime? now}) : _now = now ?? DateTime.now() {
    final rnd = Random(7);
    var id = 1;
    // Hours ago for each copy; the first few land today and yesterday.
    const ages = [
      1, 3, 20, 26, 30, 50, 75, 98, 120, 150, 190, 230, 300, 380, 460, 520,
      610, 700, 820, 950, 1100, 1300, 1500, 1800, 2100, 2500, 2900, 3400,
      4000, 4700, 5500, 6400, 7400, 8600, 9900,
    ];
    for (var i = 0; i < ages.length; i++) {
      final name = demoAssets[(i * 5 + i ~/ 3) % demoAssets.length];
      _shots.add(_entry(id++, name, ages[i], 380000 + rnd.nextInt(2400000)));
    }
    // Two exact copies, for the duplicate finder.
    final dupe = _shots[2];
    _shots.add({...dupe, 'id': id++, 'date': (dupe['date'] as int) + 60000});
    final dupe2 = _shots[9];
    _shots.add({...dupe2, 'id': id++, 'date': (dupe2['date'] as int) + 120000});
  }

  final DateTime _now;
  final _shots = <Map<String, Object>>[];
  final _trashed = <int>{};

  Map<String, Object> _entry(int id, String name, int hoursAgo, int size) {
    final date = _now.subtract(Duration(hours: hoursAgo, minutes: id * 7 % 60));
    final stamp =
        '${date.year}${_two(date.month)}${_two(date.day)}-${_two(date.hour)}${_two(date.minute)}${_two(id % 60)}';
    final suffix = name.split('_').length > 2 ? '_${name.split('_').last}' : '';
    return {
      'id': id,
      'name': 'Screenshot_$stamp$suffix.jpg',
      'date': date.millisecondsSinceEpoch,
      'size': size,
      'width': 1080,
      'height': 2340,
      'folder': 'Pictures/Screenshots/',
      'path': '',
      'asset': demoAssetPath(name),
    };
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Future<int> sdkInt() async => 34;

  @override
  Future<List<Shot>> queryScreenshots() async => _shots
      .where((m) => !_trashed.contains(m['id']))
      .map(Shot.fromMap)
      .toList();

  @override
  Future<Map<String, String>> appLabels(List<String> packages) async => const {};

  @override
  Future<Map<String, String>> hashLabels() async => const {};

  @override
  Future<Map<int, String>> md5(List<int> ids) async {
    final byId = {for (final m in _shots) m['id'] as int: m};
    return {
      for (final id in ids)
        if (byId[id] != null) id: '${byId[id]!['asset']}:${byId[id]!['size']}',
    };
  }

  @override
  Future<bool> trash(List<int> ids) async {
    _trashed.addAll(ids);
    return true;
  }

  @override
  Future<void> share(List<int> ids) async {}

  @override
  Future<void> openWith(int id) async {}
}

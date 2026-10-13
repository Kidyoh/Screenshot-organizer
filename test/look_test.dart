import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:snapsort/data/app_name.dart';
import 'package:snapsort/data/demo.dart';
import 'package:snapsort/data/look.dart';

/// Shrinks an image file to the 24 × 52 copy the phone makes (LookStore.kt).
Future<Int32List> tinyPixels(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync(),
      targetWidth: lookW, targetHeight: lookH);
  final image = (await codec.getNextFrame()).image;
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final out = Int32List(lookW * lookH);
  for (var i = 0; i < out.length; i++) {
    final r = rgba.getUint8(i * 4), g = rgba.getUint8(i * 4 + 1), b = rgba.getUint8(i * 4 + 2);
    out[i] = 0xFF000000 | r << 16 | g << 8 | b;
  }
  return out;
}

String? appOfName(String name) => switch (parseAppHint('$name.jpg')) {
      LabelHint(:final label) => label,
      _ => null,
    };

void main() {
  late Map<String, Look> looks;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    looks = {for (final a in demoAssets) a: Look(await tinyPixels(demoAssetPath(a)))};
  });

  test('fingerprints recognise WhatsApp and nothing else in the samples', () {
    for (final entry in looks.entries) {
      final expected = appOfName(entry.key) == 'WhatsApp' ? 'WhatsApp' : null;
      expect(fingerprintApp(entry.value), expected, reason: entry.key);
    }
  });

  test('identical images match, and the matcher is never wrong (hold one out)', () {
    for (final held in looks.keys) {
      final matcher = LookMatcher();
      var id = 0;
      for (final other in looks.keys) {
        final app = appOfName(other);
        if (other == held || app == null) continue;
        matcher.add(app, id++, looks[other]!);
      }
      final got = matcher.match(looks[held]!);
      // Either the right app or "don't know" — never a wrong app.
      if (got != null) expect(got, appOfName(held), reason: held);
    }

    // A re-saved copy of a known screenshot is recognised.
    final chrome = 'Screenshot_20261010-143010_Chrome';
    final matcher = LookMatcher()..add('Chrome', 1, looks[chrome]!);
    expect(matcher.match(looks[chrome]!), 'Chrome');
  });

  test('answers are deterministic and ignore reference order', () {
    final entries = looks.entries.where((e) => appOfName(e.key) != null).toList();
    String? run(Iterable<MapEntry<String, Look>> refs, Look query) {
      final m = LookMatcher();
      for (final (i, e) in refs.indexed) {
        m.add(appOfName(e.key)!, i, e.value);
      }
      return m.match(query);
    }

    for (final q in looks.values) {
      expect(run(entries, q), run(entries.reversed, q));
    }
  });
}

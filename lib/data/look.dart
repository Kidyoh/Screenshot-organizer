/// Recognises apps from how a screenshot looks, with fixed rules: no AI.
///
/// Each screenshot is shrunk to 24 × 52 pixels on the phone (LookStore.kt).
/// Two deterministic checks run on that:
///  * built-in fingerprints for apps with unmistakable colours, and
///  * matching against the person's own screenshots whose app is already known.
/// The same picture always gets the same answer, and when unsure the answer
/// is "don't know".
library;

import 'dart:typed_data';

const lookW = 24;
const lookH = 52;

/// Header band (below the status bar) and bottom bar, in rows of the tiny image.
const _headerRows = (2, 6);
const _navRows = (46, 50);

class Look {
  Look(this.px) : assert(px.length == lookW * lookH);

  /// ARGB pixels, row by row.
  final Int32List px;

  /// Share of pixels within [tolerance] of any of [colors] (0xRRGGBB), per channel.
  double fraction(List<int> colors, {(int, int) rows = (0, lookH), int tolerance = 18}) {
    var hit = 0, total = 0;
    for (var y = rows.$1; y < rows.$2; y++) {
      for (var x = 0; x < lookW; x++) {
        final p = px[y * lookW + x];
        total++;
        for (final c in colors) {
          if (((p >> 16 & 0xFF) - (c >> 16 & 0xFF)).abs() <= tolerance &&
              ((p >> 8 & 0xFF) - (c >> 8 & 0xFF)).abs() <= tolerance &&
              ((p & 0xFF) - (c & 0xFF)).abs() <= tolerance) {
            hit++;
            break;
          }
        }
      }
    }
    return total == 0 ? 0 : hit / total;
  }

  /// Share of all pixels in [rows] × [cols] that pass [test] (on 0-255 RGB).
  double share(bool Function(int r, int g, int b) test,
      {(int, int) rows = (0, lookH), (int, int) cols = (0, lookW)}) {
    var hit = 0;
    for (var y = rows.$1; y < rows.$2; y++) {
      for (var x = cols.$1; x < cols.$2; x++) {
        final p = px[y * lookW + x];
        if (test(p >> 16 & 0xFF, p >> 8 & 0xFF, p & 0xFF)) hit++;
      }
    }
    return hit / (lookW * lookH);
  }

  /// Chat apps put sent messages on the right: plenty of [bubble] in the right
  /// half, almost none touching the far left edge.
  bool sentOnRight(bool Function(int r, int g, int b) bubble, {double min = 0.02}) =>
      share(bubble, cols: (lookW ~/ 2, lookW)) >= min &&
      share(bubble, cols: (0, lookW ~/ 4)) <= 0.004;

  /// Layout signature: 4 × 4-pixel cell averages, with the header and bottom
  /// bar counted three times, since they say the most about which app it is.
  late final Float64List features = () {
    final out = <double>[];
    void cell(int x0, int y0, int w, int h, int weight) {
      var r = 0, g = 0, b = 0;
      for (var y = y0; y < y0 + h; y++) {
        for (var x = x0; x < x0 + w; x++) {
          final p = px[y * lookW + x];
          r += p >> 16 & 0xFF;
          g += p >> 8 & 0xFF;
          b += p & 0xFF;
        }
      }
      final n = w * h;
      for (var i = 0; i < weight; i++) {
        out..add(r / n)..add(g / n)..add(b / n);
      }
    }

    for (var y = 0; y + 4 <= lookH; y += 4) {
      for (var x = 0; x < lookW; x += 4) {
        cell(x, y, 4, 4, 1);
      }
    }
    for (final (a, b) in [_headerRows, _navRows]) {
      for (var x = 0; x < lookW; x += 6) {
        cell(x, a, 6, b - a, 3);
      }
    }
    return Float64List.fromList(out);
  }();

  /// Mean absolute difference per channel value (0 = identical, 255 = opposite).
  double distanceTo(Look other) {
    final a = features, b = other.features;
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum / a.length;
  }
}

class Fingerprint {
  const Fingerprint(this.app, this.why, this.test);
  final String app;
  final String why;
  final bool Function(Look) test;
}

/// Apps with colours nothing else uses together. Kept strict on purpose:
/// a wrong guess is worse than "Other".
bool _whatsAppWallpaper(int r, int g, int b) =>
    r >= 215 && r >= g && g >= b && r - b >= 6 && r - b <= 30;
bool _whatsAppSent(int r, int g, int b) => g >= 225 && g - r >= 18 && g - b >= 22;
bool _whatsAppDark(int r, int g, int b) => r <= 22 && g >= 14 && g <= 30 && b >= 20 && b <= 36;
bool _whatsAppDarkSent(int r, int g, int b) =>
    r <= 18 && g >= 78 && g <= 108 && b >= 62 && b <= 88;
bool _telegramDark(int r, int g, int b) => r <= 30 && g >= 18 && g <= 40 && b >= 30 && b <= 52;
bool _telegramDarkSent(int r, int g, int b) =>
    r >= 30 && r <= 58 && g >= 70 && g <= 100 && b >= 105 && b <= 135;

/// Apps with colours and layouts nothing else shares. Kept strict on
/// purpose: a wrong guess is worse than "Other".
final fingerprints = <Fingerprint>[
  Fingerprint('WhatsApp', 'chat wallpaper with green sent messages on the right', (l) =>
      l.share(_whatsAppWallpaper) >= 0.30 && l.sentOnRight(_whatsAppSent)),
  Fingerprint('WhatsApp', 'dark chat with teal sent messages on the right', (l) =>
      l.share(_whatsAppDark) >= 0.30 && l.sentOnRight(_whatsAppDarkSent)),
  Fingerprint('WhatsApp', 'green header', (l) =>
      l.fraction([0x075E54, 0x008069], rows: _headerRows, tolerance: 14) >= 0.7),
  Fingerprint('Telegram', 'blue header', (l) =>
      l.fraction([0x517DA2, 0x527DA3, 0x5682A3], rows: _headerRows, tolerance: 14) >= 0.7),
  Fingerprint('Telegram', 'dark chat with blue sent messages on the right', (l) =>
      l.share(_telegramDark) >= 0.30 && l.sentOnRight(_telegramDarkSent)),
  Fingerprint('Spotify', 'near-black with Spotify green', (l) =>
      l.fraction([0x121212, 0x000000], tolerance: 10) >= 0.45 &&
      l.fraction([0x1DB954, 0x1ED760], tolerance: 26) >= 0.004),
  Fingerprint('Snapchat', 'Snapchat yellow', (l) =>
      l.fraction([0xFFFC00], tolerance: 14) >= 0.12),
  Fingerprint('Viber', 'purple header', (l) =>
      l.fraction([0x7360F2, 0x665CAC], rows: _headerRows, tolerance: 14) >= 0.7),
];

String? fingerprintApp(Look look) {
  for (final f in fingerprints) {
    if (f.test(look)) return f.app;
  }
  return null;
}

/// Compares a screenshot with the person's own screenshots whose app is known.
class LookMatcher {
  final _refs = <(String app, int id, Look look)>[];

  int get length => _refs.length;

  void add(String app, int id, Look look) => _refs.add((app, id, look));

  /// Two references closer than this are the same screen type.
  static const close = 10.0;

  /// Practically the same image (a re-save or near copy).
  static const twin = 3.0;

  /// The app of the closest references if they agree, else null.
  String? match(Look look) {
    final near = [
      for (final r in _refs) (app: r.$1, id: r.$2, d: look.distanceTo(r.$3)),
    ]
      ..removeWhere((r) => r.d > close)
      // Ties broken by id so the answer never depends on order.
      ..sort((a, b) => a.d != b.d ? a.d.compareTo(b.d) : a.id.compareTo(b.id));
    if (near.isEmpty) return null;
    if (near.first.d <= twin) return near.first.app;
    if (near.length < 2) return null;
    final top = near.take(3);
    final app = top.first.app;
    return top.every((r) => r.app == app) ? app : null;
  }
}

import 'package:flutter/services.dart';

import 'shot.dart';

/// Talks to the native side (MainActivity.kt) for things MediaStore does best.
class MediaChannel {
  static const _ch = MethodChannel('snapsort/media');

  Future<int> sdkInt() async => await _ch.invokeMethod<int>('sdkInt') ?? 0;

  Future<List<Shot>> queryScreenshots() async {
    final raw = await _ch.invokeListMethod<Map<dynamic, dynamic>>('query');
    return (raw ?? const []).map(Shot.fromMap).toList();
  }

  Future<Map<String, String>> appLabels(List<String> packages) async {
    if (packages.isEmpty) return const {};
    final raw = await _ch.invokeMapMethod<String, String>(
        'appLabels', {'packages': packages});
    return raw ?? const {};
  }

  Future<Map<String, String>> hashLabels() async =>
      await _ch.invokeMapMethod<String, String>('hashLabels') ?? const {};

  Future<Map<int, String>> md5(List<int> ids) async {
    final raw =
        await _ch.invokeMapMethod<String, String>('md5', {'ids': ids}) ?? {};
    return raw.map((k, v) => MapEntry(int.parse(k), v));
  }

  /// Moves to the system recycle bin (Android 11+) or deletes (older).
  /// Returns false if the user said no.
  Future<bool> trash(List<int> ids) async =>
      await _ch.invokeMethod<bool>('trash', {'ids': ids}) ?? false;

  Future<void> share(List<int> ids) => _ch.invokeMethod('share', {'ids': ids});

  Future<void> openWith(int id) => _ch.invokeMethod('openWith', {
        'ids': [id]
      });
}

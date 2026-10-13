import 'dart:typed_data';

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

  /// Whether the person turned on Usage access for SnapSort.
  Future<bool> usageAccess() async => await _ch.invokeMethod<bool>('usageAccess') ?? false;

  Future<void> openUsageAccess() => _ch.invokeMethod('openUsageAccess');

  /// Screenshot id -> package of the app that was open when it was taken,
  /// for the ones Android's usage history (or earlier lookups) can answer.
  Future<Map<int, String>> appsAt(Map<int, int> times) async {
    if (times.isEmpty) return const {};
    final raw = await _ch.invokeMapMethod<String, String>('appsAt', {
          'times': times.map((k, v) => MapEntry('$k', v)),
        }) ??
        {};
    return raw.map((k, v) => MapEntry(int.parse(k), v));
  }

  /// 24 × 52 ARGB copies of screenshots, for recognising apps by look.
  Future<Map<int, Int32List>> looks(List<int> ids) async {
    if (ids.isEmpty) return const {};
    final raw = await _ch.invokeMapMethod<String, Int32List>('looks', {'ids': ids}) ?? {};
    return raw.map((k, v) => MapEntry(int.parse(k), v));
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

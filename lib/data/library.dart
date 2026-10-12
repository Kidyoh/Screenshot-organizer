import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_name.dart';
import 'media_channel.dart';
import 'shot.dart';

class AppGroup {
  AppGroup(this.name, this.shots)
      : totalSize = shots.fold(0, (sum, s) => sum + s.size);
  final String name;
  final List<Shot> shots;
  final int totalSize;
}

typedef PermissionCheck = Future<PermissionState> Function({required bool ask});

const _imagePermission = PermissionRequestOption(
  androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
);

Future<PermissionState> _photoManagerPermission({required bool ask}) => ask
    ? PhotoManager.requestPermissionExtend(requestOption: _imagePermission)
    : PhotoManager.getPermissionState(requestOption: _imagePermission);

/// All the app's state: the screenshots, how they're grouped, albums,
/// favourites and the duplicate scan.
class Library extends ChangeNotifier {
  Library({MediaChannel? channel, PermissionCheck? permission})
      : _channel = channel ?? MediaChannel(),
        _permission = permission ?? _photoManagerPermission;

  final MediaChannel _channel;
  final PermissionCheck _permission;

  PermissionState? permission;
  int sdkInt = 0;
  bool loading = false;
  bool loadedOnce = false;
  String? error;

  List<Shot> shots = const [];
  Map<int, Shot> _byId = const {};
  List<AppGroup> apps = const [];

  final Set<int> favorites = {};
  final LinkedHashMap<String, List<int>> albums = LinkedHashMap();

  bool scanningDuplicates = false;
  double duplicateProgress = 0;
  List<List<int>>? _duplicateIds;

  final Map<String, String> _labelCache = {};
  Map<String, String>? _hashLabels;

  bool get hasAccess =>
      permission == PermissionState.authorized ||
      permission == PermissionState.limited;
  /// Android 11+ asks for confirmation itself and keeps deleted files in the
  /// recycle bin for 30 days; older versions delete straight away.
  bool get trashGoesToBin => sdkInt >= 30;
  bool get isLimited => permission == PermissionState.limited;
  int get totalSize => shots.fold(0, (sum, s) => sum + s.size);
  Shot? byId(int id) => _byId[id];

  Future<void> start() async {
    try {
      sdkInt = await _channel.sdkInt();
    } catch (_) {}
    await _loadAlbums();
    await checkPermission(ask: false);
  }

  Future<void> checkPermission({required bool ask}) async {
    try {
      permission = await _permission(ask: ask);
    } catch (e) {
      error = '$e';
    }
    notifyListeners();
    if (hasAccess) await refresh();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      final list = await _channel.queryScreenshots();
      await _assignApps(list);
      list.sort((a, b) => b.date.compareTo(a.date));
      shots = list;
      _byId = {for (final s in list) s.id: s};
      apps = _groupByApp(list);
      error = null;
    } catch (e) {
      error = 'Could not read screenshots: $e';
    } finally {
      loading = false;
      loadedOnce = true;
      notifyListeners();
    }
  }

  Future<void> _assignApps(List<Shot> list) async {
    final hints = <Shot, AppHint?>{
      for (final s in list) s: parseAppHint(s.name, s.folder),
    };
    final unknownPackages = hints.values
        .whereType<PackageHint>()
        .map((h) => h.package)
        .where((p) => !_labelCache.containsKey(p))
        .toSet()
        .toList();
    if (unknownPackages.isNotEmpty) {
      try {
        final labels = await _channel.appLabels(unknownPackages);
        for (final p in unknownPackages) {
          _labelCache[p] = labels[p] ?? prettifyPackage(p);
        }
      } catch (_) {
        for (final p in unknownPackages) {
          _labelCache[p] = prettifyPackage(p);
        }
      }
    }
    if (_hashLabels == null && hints.values.any((h) => h is HashHint)) {
      try {
        _hashLabels = await _channel.hashLabels();
      } catch (_) {
        _hashLabels = const {};
      }
    }

    // Merge spellings that only differ by case ("Chrome" / "chrome").
    final canonical = <String, String>{};
    for (final entry in hints.entries) {
      final name = switch (entry.value) {
        LabelHint(:final label) => label,
        PackageHint(:final package) => _labelCache[package]!,
        HashHint(:final md5) => _hashLabels?[md5] ?? Shot.otherApp,
        null => Shot.otherApp,
      };
      entry.key.app = canonical.putIfAbsent(name.toLowerCase(), () => name);
    }
  }

  static List<AppGroup> _groupByApp(List<Shot> list) {
    final map = <String, List<Shot>>{};
    for (final s in list) {
      map.putIfAbsent(s.app, () => []).add(s);
    }
    final groups = map.entries.map((e) => AppGroup(e.key, e.value)).toList();
    groups.sort((a, b) {
      if (a.name == Shot.otherApp) return 1;
      if (b.name == Shot.otherApp) return -1;
      final c = b.shots.length.compareTo(a.shots.length);
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  List<Shot> resolve(Iterable<int> ids) =>
      ids.map((id) => _byId[id]).whereType<Shot>().toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Shot> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return shots;
    return shots
        .where((s) =>
            s.app.toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q) ||
            monthYear(s.date).toLowerCase().contains(q))
        .toList();
  }

  List<Shot> olderThan(Duration age) {
    final cutoff = DateTime.now().subtract(age);
    return shots.where((s) => s.date.isBefore(cutoff)).toList();
  }

  List<Shot> largerThan(int bytes) =>
      shots.where((s) => s.size >= bytes).toList()
        ..sort((a, b) => b.size.compareTo(a.size));

  // ---- Deleting / sharing ----

  /// Sends shots to the recycle bin. Returns false if the user cancelled.
  Future<bool> trash(Iterable<Shot> items) async {
    final ids = items.map((s) => s.id).toList();
    final removed = <int>[];
    var ok = true;
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      if (!await _channel.trash(chunk)) {
        ok = false;
        break;
      }
      removed.addAll(chunk);
    }
    if (removed.isNotEmpty) {
      favorites.removeAll(removed);
      for (final list in albums.values) {
        list.removeWhere(removed.toSet().contains);
      }
      await _saveAlbums();
      await refresh();
    }
    return ok;
  }

  Future<void> share(Iterable<Shot> items) =>
      _channel.share(items.map((s) => s.id).toList());

  Future<void> openWith(Shot shot) => _channel.openWith(shot.id);

  // ---- Favourites & albums ----

  bool isFavorite(Shot s) => favorites.contains(s.id);

  void setFavorite(Iterable<Shot> items, bool value) {
    for (final s in items) {
      value ? favorites.add(s.id) : favorites.remove(s.id);
    }
    _saveAlbums();
    notifyListeners();
  }

  List<Shot> get favoriteShots => resolve(favorites);
  List<Shot> albumShots(String name) => resolve(albums[name] ?? const []);

  bool createAlbum(String name) {
    name = name.trim();
    if (name.isEmpty || albums.containsKey(name)) return false;
    albums[name] = [];
    _saveAlbums();
    notifyListeners();
    return true;
  }

  void addToAlbum(String name, Iterable<Shot> items) {
    final list = albums.putIfAbsent(name, () => []);
    for (final s in items) {
      if (!list.contains(s.id)) list.add(s.id);
    }
    _saveAlbums();
    notifyListeners();
  }

  void removeFromAlbum(String name, Iterable<Shot> items) {
    final ids = items.map((s) => s.id).toSet();
    albums[name]?.removeWhere(ids.contains);
    _saveAlbums();
    notifyListeners();
  }

  bool renameAlbum(String from, String to) {
    to = to.trim();
    if (to.isEmpty || from == to || albums.containsKey(to)) return false;
    final entries = albums.entries.toList();
    albums
      ..clear()
      ..addEntries(entries.map((e) => e.key == from ? MapEntry(to, e.value) : e));
    _saveAlbums();
    notifyListeners();
    return true;
  }

  void deleteAlbum(String name) {
    albums.remove(name);
    _saveAlbums();
    notifyListeners();
  }

  Future<void> _loadAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      favorites
        ..clear()
        ..addAll((prefs.getStringList('favorites') ?? const []).map(int.parse));
      final raw = prefs.getString('albums');
      albums.clear();
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in decoded.entries) {
          albums[e.key] = (e.value as List).map((v) => (v as num).toInt()).toList();
        }
      }
    } catch (e) {
      debugPrint('Could not load albums: $e');
    }
  }

  Future<void> _saveAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'favorites', favorites.map((id) => '$id').toList());
      await prefs.setString('albums', jsonEncode(albums));
    } catch (e) {
      debugPrint('Could not save albums: $e');
    }
  }

  // ---- Duplicates ----

  /// Groups of byte-identical screenshots, oldest first in each group.
  List<List<Shot>>? get duplicateGroups {
    final ids = _duplicateIds;
    if (ids == null) return null;
    return ids
        .map((g) => g.map((id) => _byId[id]).whereType<Shot>().toList()
          ..sort((a, b) => a.date.compareTo(b.date)))
        .where((g) => g.length > 1)
        .toList();
  }

  Future<void> scanDuplicates() async {
    if (scanningDuplicates) return;
    scanningDuplicates = true;
    duplicateProgress = 0;
    notifyListeners();
    try {
      // Only files with the exact same size can be identical, so hash just those.
      final bySize = <int, List<Shot>>{};
      for (final s in shots) {
        if (s.size > 0) bySize.putIfAbsent(s.size, () => []).add(s);
      }
      final candidates = bySize.values
          .where((g) => g.length > 1)
          .expand((g) => g)
          .map((s) => s.id)
          .toList();
      final hashes = <int, String>{};
      for (var i = 0; i < candidates.length; i += 40) {
        final end = i + 40 > candidates.length ? candidates.length : i + 40;
        hashes.addAll(await _channel.md5(candidates.sublist(i, end)));
        duplicateProgress = end / candidates.length;
        notifyListeners();
      }
      final byHash = <String, List<int>>{};
      for (final e in hashes.entries) {
        final size = _byId[e.key]?.size ?? 0;
        byHash.putIfAbsent('$size:${e.value}', () => []).add(e.key);
      }
      final groups = byHash.values.where((g) => g.length > 1).toList();
      groups.sort((a, b) => _newest(b).compareTo(_newest(a)));
      _duplicateIds = groups;
    } catch (e) {
      error = 'Duplicate scan failed: $e';
    } finally {
      scanningDuplicates = false;
      notifyListeners();
    }
  }

  DateTime _newest(List<int> ids) => ids
      .map((id) => _byId[id]?.date ?? DateTime(0))
      .reduce((a, b) => a.isAfter(b) ? a : b);
}

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_name.dart';
import 'look.dart';
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

  /// Screenshots the person chose to keep in Swipe to clean.
  final Set<int> reviewed = {};
  final LinkedHashMap<String, List<int>> albums = LinkedHashMap();

  bool scanningDuplicates = false;
  double duplicateProgress = 0;
  List<List<int>>? _duplicateIds;

  final Map<String, String> _labelCache = {};

  /// Tiny copies of screenshots, for recognising apps by look.
  final Map<int, Look> _looks = {};
  int _lookPass = 0;

  /// The background look-up is still working through screenshots.
  bool recognising = false;

  /// Apps the person picked by hand; these always win.
  final Map<int, String> appOverrides = {};

  /// Usage access is on, so untagged screenshots get their app from history.
  bool usageAccess = false;

  /// The person said "Not now" to the usage access card.
  bool usageCardDismissed = false;

  /// The one-time usage access prompt has been shown.
  bool usagePromptShown = false;

  void markUsagePromptShown() {
    usagePromptShown = true;
    _saveAlbums();
  }
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
      _recognise(); // instant, from tiny copies already made
      apps = _groupByApp(list);
      error = null;
    } catch (e) {
      error = 'Could not read screenshots: $e';
    } finally {
      loading = false;
      loadedOnce = true;
      notifyListeners();
    }
    unawaited(_recogniseInBackground());
  }

  /// Screenshots with a known app, used as references: the newest few per app.
  List<Shot> get _references {
    final perApp = <String, List<Shot>>{};
    for (final s in shots) {
      if (s.appSource == AppSource.unknown || s.appSource == AppSource.looks) continue;
      final list = perApp.putIfAbsent(s.app, () => []);
      if (list.length < 25) list.add(s);
    }
    return perApp.values.expand((l) => l).toList();
  }

  /// Labels unknown screenshots from their looks, using only tiny copies
  /// already fetched. Returns how many changed.
  int _recognise() {
    final unknown = shots.where((s) => s.appSource == AppSource.unknown).toList();
    if (unknown.isEmpty || _looks.isEmpty) return 0;
    final matcher = LookMatcher();
    for (final r in _references) {
      final look = _looks[r.id];
      if (look != null) matcher.add(r.app, r.id, look);
    }
    final names = {for (final s in shots) s.app.toLowerCase(): s.app};
    var changed = 0;
    for (final s in unknown) {
      final look = _looks[s.id];
      if (look == null) continue;
      final app = fingerprintApp(look) ?? matcher.match(look);
      if (app == null) continue;
      s.app = names.putIfAbsent(app.toLowerCase(), () => app);
      s.appSource = AppSource.looks;
      changed++;
    }
    return changed;
  }

  /// Makes tiny copies for unknown screenshots and their references, a batch
  /// at a time (slow on budget phones the first time, then cached for good).
  Future<void> _recogniseInBackground() async {
    final pass = ++_lookPass;
    final unknown = shots.where((s) => s.appSource == AppSource.unknown).map((s) => s.id);
    final wanted = [..._references.map((s) => s.id), ...unknown]
        .where((id) => !_looks.containsKey(id))
        .toList();
    if (wanted.isEmpty) return;
    recognising = true;
    notifyListeners();
    try {
      for (var i = 0; i < wanted.length; i += 40) {
        final batch = wanted.sublist(i, i + 40 > wanted.length ? wanted.length : i + 40);
        final got = await _channel.looks(batch);
        if (pass != _lookPass) return; // a newer refresh took over
        got.forEach((id, px) {
          if (px.length == lookW * lookH) _looks[id] = Look(px);
        });
        if (_recognise() > 0) {
          apps = _groupByApp(shots);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Could not recognise screenshots by look: $e');
    } finally {
      if (pass == _lookPass) {
        recognising = false;
        notifyListeners();
      }
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

    String? fromName(AppHint? hint) => switch (hint) {
          LabelHint(:final label) => label,
          PackageHint(:final package) => _labelCache[package]!,
          HashHint(:final md5) => _hashLabels?[md5],
          null => null,
        };

    // Screenshots the name doesn't explain: ask Android's usage history.
    try {
      usageAccess = await _channel.usageAccess();
    } catch (_) {
      usageAccess = false;
    }
    final untagged = {
      for (final e in hints.entries)
        if (fromName(e.value) == null && !appOverrides.containsKey(e.key.id))
          e.key.id: e.key.date.millisecondsSinceEpoch,
    };
    var used = const <int, String>{};
    try {
      used = await _channel.appsAt(untagged);
    } catch (_) {}
    final usedPackages = used.values.where((p) => !_labelCache.containsKey(p)).toSet().toList();
    if (usedPackages.isNotEmpty) {
      Map<String, String> labels = const {};
      try {
        labels = await _channel.appLabels(usedPackages);
      } catch (_) {}
      for (final p in usedPackages) {
        _labelCache[p] = labels[p] ?? prettifyPackage(p);
      }
    }

    // Merge spellings that only differ by case ("Chrome" / "chrome").
    final canonical = <String, String>{};
    for (final entry in hints.entries) {
      final shot = entry.key;
      final manual = appOverrides[shot.id];
      final named = fromName(entry.value);
      final usage = used[shot.id] == null ? null : _labelCache[used[shot.id]!];
      final (name, source) = manual != null
          ? (manual, AppSource.manual)
          : named != null
              ? (named, AppSource.fileName)
              : usage != null
                  ? (usage, AppSource.usage)
                  : (Shot.otherApp, AppSource.unknown);
      shot.app = canonical.putIfAbsent(name.toLowerCase(), () => name);
      shot.appSource = source;
    }
  }

  /// Screenshots still filed under Other.
  int get unknownCount => shots.where((s) => s.appSource == AppSource.unknown).length;

  Future<void> openUsageAccess() => _channel.openUsageAccess();

  void dismissUsageCard() {
    usageCardDismissed = true;
    _saveAlbums();
    notifyListeners();
  }

  /// Files screenshots under [app] by hand, or back to automatic with null.
  Future<void> setApp(Iterable<Shot> items, String? app) async {
    final name = app?.trim();
    for (final s in items) {
      if (name == null || name.isEmpty) {
        appOverrides.remove(s.id);
      } else {
        appOverrides[s.id] = name;
      }
    }
    await _saveAlbums();
    await refresh();
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
      reviewed.removeAll(removed);
      appOverrides.removeWhere((id, _) => removed.contains(id));
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
      reviewed
        ..clear()
        ..addAll((prefs.getStringList('reviewed') ?? const []).map(int.parse));
      appOverrides.clear();
      final rawApps = prefs.getString('appOverrides');
      if (rawApps != null) {
        (jsonDecode(rawApps) as Map<String, dynamic>)
            .forEach((k, v) => appOverrides[int.parse(k)] = v as String);
      }
      usageCardDismissed = prefs.getBool('usageCardDismissed') ?? false;
      usagePromptShown = prefs.getBool('usagePromptShown') ?? false;
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
      await prefs.setStringList('reviewed', reviewed.map((id) => '$id').toList());
      await prefs.setString(
          'appOverrides', jsonEncode(appOverrides.map((k, v) => MapEntry('$k', v))));
      await prefs.setBool('usageCardDismissed', usageCardDismissed);
      await prefs.setBool('usagePromptShown', usagePromptShown);
    } catch (e) {
      debugPrint('Could not save albums: $e');
    }
  }

  // ---- Swipe to clean ----

  /// Screenshots not yet kept in Swipe to clean, oldest first.
  List<Shot> get unreviewed =>
      shots.where((s) => !reviewed.contains(s.id)).toList().reversed.toList();

  void setReviewed(Shot shot, bool value) {
    value ? reviewed.add(shot.id) : reviewed.remove(shot.id);
    _saveAlbums();
    notifyListeners();
  }

  void resetReviewed() {
    reviewed.clear();
    _saveAlbums();
    notifyListeners();
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

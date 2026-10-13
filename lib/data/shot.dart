import 'package:photo_manager/photo_manager.dart';

/// How SnapSort knows which app a screenshot came from.
enum AppSource {
  /// The phone wrote it into the file name or folder.
  fileName,

  /// Android's usage history: the app that was open at that moment.
  usage,

  /// The person picked it.
  manual,

  /// Recognised from how the screenshot looks (fixed rules, no AI).
  looks,

  /// No clue yet.
  unknown,
}

/// One screenshot on the phone.
class Shot {
  Shot({
    required this.id,
    required this.name,
    required this.date,
    required this.size,
    required this.width,
    required this.height,
    required this.folder,
    required this.path,
    this.app = otherApp,
    this.asset,
  });

  factory Shot.fromMap(Map<dynamic, dynamic> m) => Shot(
        id: (m['id'] as num).toInt(),
        name: m['name'] as String? ?? '',
        date: DateTime.fromMillisecondsSinceEpoch((m['date'] as num).toInt()),
        size: (m['size'] as num?)?.toInt() ?? 0,
        width: (m['width'] as num?)?.toInt() ?? 0,
        height: (m['height'] as num?)?.toInt() ?? 0,
        folder: m['folder'] as String? ?? '',
        path: m['path'] as String? ?? '',
        asset: m['asset'] as String?,
      );

  static const otherApp = 'Other';

  final int id;
  final String name;
  final DateTime date;
  final int size;
  final int width;
  final int height;

  /// Folder relative to the storage root, e.g. "Pictures/Screenshots/".
  final String folder;

  /// Absolute file path, used for the full-size viewer.
  final String path;

  /// Which app the screenshot was taken in, or [otherApp].
  String app;

  AppSource appSource = AppSource.unknown;

  /// Bundled image used instead of the media store in demo mode.
  final String? asset;

  double get aspect => width > 0 && height > 0 ? width / height : 9 / 19.5;

  late final AssetEntity entity = AssetEntity(
    id: '$id',
    typeInt: AssetType.image.index,
    width: width,
    height: height,
    title: name,
  );
}

/// A titled run of screenshots in a grid.
class Section {
  const Section(this.title, this.shots, {this.subtitle});
  final String title;
  final String? subtitle;
  final List<Shot> shots;
}

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];
const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

String shortDate(DateTime d) {
  final now = DateTime.now();
  final base = '${_shortMonths[d.month - 1]} ${d.day}';
  return d.year == now.year ? base : '$base, ${d.year}';
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String longDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

String greeting(DateTime now) => now.hour < 5
    ? 'Up late'
    : now.hour < 12
        ? 'Good morning'
        : now.hour < 18
            ? 'Good afternoon'
            : 'Good evening';

String timeOfDay(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// Groups newest-first shots into Today / Yesterday / This week / months.
List<Section> sectionsByDate(List<Shot> shots, {DateTime? now}) {
  now ??= DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 6));
  final out = <Section>[];
  String? current;
  List<Shot>? bucket;
  for (final s in shots) {
    final String title;
    if (!s.date.isBefore(today)) {
      title = 'Today';
    } else if (!s.date.isBefore(yesterday)) {
      title = 'Yesterday';
    } else if (!s.date.isBefore(weekAgo)) {
      title = 'This week';
    } else {
      title = monthYear(s.date);
    }
    if (title != current) {
      current = title;
      bucket = [];
      out.add(Section(title, bucket));
    }
    bucket!.add(s);
  }
  return out;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var v = bytes / 1024;
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(v >= 100 || i == 0 ? 0 : 1)} ${units[i]}';
}

String formatCount(int n, String noun) {
  final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '$s $noun${n == 1 ? '' : 's'}';
}

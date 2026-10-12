/// Works out which app a screenshot was taken in, purely from its file name
/// and folder. Phone makers bake this into the name in a few different ways:
///
///   Samsung / Pixel:  Screenshot_20240115-093012_WhatsApp.jpg
///   Xiaomi (MIUI):    Screenshot_2024-01-15-09-30-12-345_com.whatsapp.jpg
///   Oppo / OnePlus:   Screenshot_2024-01-15-09-30-12-34_{md5 of package}.jpg
///
/// and a screenshot moved into `Screenshots/<App>/` is filed under that folder.
library;

sealed class AppHint {
  const AppHint();
}

/// A human readable app name, e.g. "WhatsApp".
class LabelHint extends AppHint {
  const LabelHint(this.label);
  final String label;

  @override
  bool operator ==(Object other) => other is LabelHint && other.label == label;
  @override
  int get hashCode => label.hashCode;
  @override
  String toString() => 'LabelHint($label)';
}

/// An Android package name, e.g. "com.whatsapp".
class PackageHint extends AppHint {
  const PackageHint(this.package);
  final String package;

  @override
  bool operator ==(Object other) =>
      other is PackageHint && other.package == package;
  @override
  int get hashCode => package.hashCode;
  @override
  String toString() => 'PackageHint($package)';
}

/// The MD5 of a package name, as used by ColorOS / OxygenOS.
class HashHint extends AppHint {
  const HashHint(this.md5);
  final String md5;

  @override
  bool operator ==(Object other) => other is HashHint && other.md5 == md5;
  @override
  int get hashCode => md5.hashCode;
  @override
  String toString() => 'HashHint($md5)';
}

final _screenshotFolder = RegExp(r'^screen[ _-]?shots?$', caseSensitive: false);
final _prefix = RegExp(
  r'^(screen[ _-]?shot|scrnshot|screen[ _-]?capture|capture)s?',
  caseSensitive: false,
);
final _copySuffix = RegExp(r'(\s*\(\d+\)|~\d+)$');
final _leadingNoise = RegExp(
  r'^(?:[ _\-.]+|\d+(?=[ _\-.]|$)|(?:at|from)(?=[ _]))',
  caseSensitive: false,
);
final _trailingNoise = RegExp(
  r'(?:[ _\-.]+|(?<=^|[ _\-.])\d+|(?<=[ _\-.])(?:am|pm))$',
  caseSensitive: false,
);
final _letters = RegExp(r'[A-Za-z]');
final _md5 = RegExp(r'^[0-9a-f]{32}$');
final _package = RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$');

/// Returns what the file name / folder says about the source app, or null
/// when it gives no clue (e.g. "Screenshot_20240115-093012.png").
AppHint? parseAppHint(String fileName, [String? folder]) {
  if (folder != null && folder.isNotEmpty) {
    final segs = folder.split('/').where((s) => s.isNotEmpty).toList();
    final i = segs.indexWhere(_screenshotFolder.hasMatch);
    if (i >= 0 && i + 1 < segs.length) {
      final hint = _classify(segs[i + 1]);
      if (hint != null) return hint;
    }
  }

  var s = fileName;
  final dot = s.lastIndexOf('.');
  if (dot > 0) s = s.substring(0, dot);
  s = s.replaceFirst(_copySuffix, '');
  s = s.replaceFirst(_prefix, '');
  s = _stripRepeatedly(s, _leadingNoise, fromStart: true);
  s = _stripRepeatedly(s, _trailingNoise, fromStart: false);
  return _classify(s);
}

String _stripRepeatedly(String s, RegExp re, {required bool fromStart}) {
  while (true) {
    final m = re.firstMatch(s);
    if (m == null || m.end == m.start) return s;
    s = fromStart ? s.substring(m.end) : s.substring(0, m.start);
  }
}

AppHint? _classify(String raw) {
  final s = raw.trim();
  if (s.isEmpty || !_letters.hasMatch(s)) return null;
  if (_md5.hasMatch(s)) return HashHint(s);
  if (_package.hasMatch(s)) return PackageHint(s);
  final label = s.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (label.length < 2) return null;
  return LabelHint(label);
}

const knownPackages = <String, String>{
  'com.whatsapp': 'WhatsApp',
  'com.whatsapp.w4b': 'WhatsApp Business',
  'com.instagram.android': 'Instagram',
  'com.facebook.katana': 'Facebook',
  'com.facebook.lite': 'Facebook Lite',
  'com.facebook.orca': 'Messenger',
  'com.zhiliaoapp.musically': 'TikTok',
  'com.ss.android.ugc.trill': 'TikTok',
  'com.twitter.android': 'X',
  'org.telegram.messenger': 'Telegram',
  'org.thoughtcrime.securesms': 'Signal',
  'com.snapchat.android': 'Snapchat',
  'com.google.android.youtube': 'YouTube',
  'com.android.chrome': 'Chrome',
  'com.google.android.apps.maps': 'Maps',
  'com.google.android.gm': 'Gmail',
  'com.google.android.apps.photos': 'Photos',
  'com.google.android.apps.messaging': 'Messages',
  'com.google.android.googlequicksearchbox': 'Google',
  'com.google.android.calendar': 'Calendar',
  'com.google.android.apps.docs': 'Drive',
  'com.google.android.keep': 'Keep',
  'com.spotify.music': 'Spotify',
  'com.reddit.frontpage': 'Reddit',
  'com.discord': 'Discord',
  'com.linkedin.android': 'LinkedIn',
  'com.pinterest': 'Pinterest',
  'com.netflix.mediaclient': 'Netflix',
  'com.amazon.mshop.android.shopping': 'Amazon',
  'org.mozilla.firefox': 'Firefox',
  'com.microsoft.teams': 'Teams',
  'com.microsoft.office.outlook': 'Outlook',
  'com.slack': 'Slack',
  'com.android.settings': 'Settings',
  'com.samsung.android.messaging': 'Messages',
  'com.sec.android.app.sbrowser': 'Samsung Internet',
  'com.sec.android.gallery3d': 'Gallery',
  'com.miui.gallery': 'Gallery',
  'com.openai.chatgpt': 'ChatGPT',
  'com.anthropic.claude': 'Claude',
  'com.android.systemui': 'System',
  'com.google.android.apps.nexuslauncher': 'Home screen',
  'com.sec.android.app.launcher': 'Home screen',
  'com.miui.home': 'Home screen',
};

const _noiseSegments = {
  'com', 'org', 'net', 'io', 'co', 'me', 'tv', 'app', 'apps', 'android',
  'mobile', 'client', 'main', 'free', 'lite', 'pro', 'www',
};
const _vendorSegments = {
  'google', 'samsung', 'sec', 'microsoft', 'miui', 'xiaomi', 'huawei',
  'oneplus', 'oppo', 'coloros', 'heytap', 'motorola', 'sony', 'lge',
};

/// Best-effort readable name for a package that isn't installed (or that we
/// can't see), e.g. "com.spotify.music" -> "Spotify".
String prettifyPackage(String pkg) {
  final known = knownPackages[pkg.toLowerCase()];
  if (known != null) return known;
  final parts = pkg
      .split('.')
      .where((p) => p.isNotEmpty && !_noiseSegments.contains(p.toLowerCase()))
      .toList();
  if (parts.isEmpty) return _capitalize(pkg.split('.').last);
  final brand = parts.firstWhere(
    (p) => !_vendorSegments.contains(p.toLowerCase()),
    orElse: () => parts.last,
  );
  // For vendor apps ("com.google.android.apps.maps") the product is last.
  final pick = _vendorSegments.contains(parts.first.toLowerCase())
      ? parts.last
      : brand;
  return _capitalize(pick);
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

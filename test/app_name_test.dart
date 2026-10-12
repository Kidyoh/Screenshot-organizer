import 'package:flutter_test/flutter_test.dart';
import 'package:snapsort/data/app_name.dart';

void main() {
  group('parseAppHint', () {
    test('Samsung / Pixel style keeps the app label', () {
      expect(parseAppHint('Screenshot_20240115-093012_WhatsApp.jpg'),
          const LabelHint('WhatsApp'));
      expect(parseAppHint('Screenshot_20240115-093012_Samsung Internet.jpg'),
          const LabelHint('Samsung Internet'));
      expect(parseAppHint('Screenshot_20240115_093012_9GAG.png'),
          const LabelHint('9GAG'));
    });

    test('Xiaomi style gives the package', () {
      expect(
          parseAppHint('Screenshot_2023-05-12-14-30-12-123_com.android.chrome.jpg'),
          const PackageHint('com.android.chrome'));
    });

    test('ColorOS style gives the package hash', () {
      expect(
          parseAppHint(
              'Screenshot_2023-08-12-10-11-12-34_965bbf4d18d205f782c6b8409c5773a4.jpg'),
          const HashHint('965bbf4d18d205f782c6b8409c5773a4'));
    });

    test('names without an app give null', () {
      expect(parseAppHint('Screenshot_20240115-093012.png'), isNull);
      expect(parseAppHint('Screenshot 2024-01-15 at 10.30.12.png'), isNull);
      expect(parseAppHint('Screenshot_20240115-093012 (1).png'), isNull);
      expect(parseAppHint('IMG_20240101_101010.jpg'), const LabelHint('IMG'));
    });

    test('copy suffixes are ignored', () {
      expect(parseAppHint('Screenshot_20240115-093012_Chrome (2).jpg'),
          const LabelHint('Chrome'));
    });

    test('a subfolder under Screenshots wins', () {
      expect(
          parseAppHint('Screenshot_20240115-093012.png',
              'Pictures/Screenshots/Instagram/'),
          const LabelHint('Instagram'));
      expect(
          parseAppHint('Screenshot_20240115-093012_Chrome.png',
              'DCIM/Screenshots/'),
          const LabelHint('Chrome'));
    });
  });

  group('prettifyPackage', () {
    test('known packages', () {
      expect(prettifyPackage('com.zhiliaoapp.musically'), 'TikTok');
      expect(prettifyPackage('com.facebook.orca'), 'Messenger');
    });
    test('unknown packages', () {
      expect(prettifyPackage('com.spotify.music.beta'), 'Spotify');
      expect(prettifyPackage('com.google.android.apps.fitness'), 'Fitness');
      expect(prettifyPackage('net.example'), 'Example');
    });
  });
}

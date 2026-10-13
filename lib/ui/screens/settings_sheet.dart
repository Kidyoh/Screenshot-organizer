import 'package:flutter/material.dart';

import '../actions.dart';
import '../design/tokens.dart';
import '../scope.dart';
import '../widgets/common.dart';

Future<void> showSettings(BuildContext context) => showAppSheet<void>(context, (context) {
      final prefs = PrefsScope.of(context);
      final lib = LibraryScope.of(context);
      final t = context.tokens;
      Widget fact(IconData i, Color c, String title, String body) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconBadge(i, color: c, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(body, style: context.text.bodySmall),
                ]),
              ),
            ]),
          );
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeading(title: 'Settings'),
            const SectionLabel('Appearance', padding: EdgeInsets.only(bottom: 10, left: 2)),
            PillTabs<ThemeMode>(
              values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
              labelOf: (m) => switch (m) {
                ThemeMode.system => 'Auto',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              },
              selected: prefs.themeMode,
              onChanged: prefs.setThemeMode,
            ),
            const SectionLabel('How it works', padding: EdgeInsets.fromLTRB(2, 26, 0, 12)),
            fact(Icons.folder_open_rounded, Brand.violet, 'Reads your Screenshots folder',
                'Anything saved in a folder called Screenshots shows up, including subfolders.'),
            fact(Icons.apps_rounded, Brand.mint, 'Sorts by app from the file name',
                'Most phones write the app into the screenshot\'s name.'),
            fact(Icons.visibility_outlined, Brand.coral, 'Recognises apps by how they look',
                'Fixed rules, no AI: well-known app colours and layouts, and matches with your own screenshots whose app is known.'),
            fact(
              Icons.manage_search_rounded,
              Brand.amber,
              'Usage access: ${lib.usageAccess ? 'on' : 'off'}',
              lib.usageAccess
                  ? 'For screenshots without the app in the name, SnapSort checks which app was open when you took them.'
                  : 'Turn it on so SnapSort can tell which app was open for screenshots without the app in the name.',
            ),
            if (!lib.usageAccess)
              Padding(
                padding: const EdgeInsets.only(left: 54, bottom: 14),
                child: PillButton(
                  label: 'Turn on usage access',
                  style: PillStyle.soft,
                  height: 42,
                  expand: false,
                  onTap: lib.openUsageAccess,
                ),
              ),
            fact(Icons.wifi_off_rounded, Brand.mint, 'Private by design',
                'No internet permission and no AI. Albums and favourites stay on this phone.'),
            const SizedBox(height: 6),
            PillButton(
              label: lib.loading ? 'Rescanning…' : 'Rescan screenshots',
              icon: Icons.refresh_rounded,
              style: PillStyle.soft,
              busy: lib.loading,
              onTap: lib.refresh,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('SnapSort 1.3.1', style: context.text.bodySmall?.copyWith(color: t.faint)),
            ),
          ],
        ),
      );
    });

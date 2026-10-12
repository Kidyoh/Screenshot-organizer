import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'scope.dart';

/// First-run screen that explains the app and asks for photo access.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = LibraryScope.of(context);
    final theme = Theme.of(context);
    final denied = lib.permission == PermissionState.denied ||
        lib.permission == PermissionState.restricted;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.auto_awesome_mosaic_outlined,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 28),
              Text('SnapSort',
                  style: theme.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text('Your screenshots, sorted.',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 24),
              const _Point(Icons.apps, 'Grouped by the app you took them in'),
              const _Point(Icons.calendar_month_outlined, 'Sorted by day and month'),
              const _Point(Icons.cleaning_services_outlined,
                  'Find duplicates, old and oversized screenshots'),
              const _Point(Icons.wifi_off_outlined,
                  'Works offline. No AI, nothing leaves your phone'),
              const Spacer(),
              if (denied)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Photo access was turned off. You can turn it back on in Settings.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Allow access to screenshots'),
                  onPressed: () => lib.checkPermission(ask: true),
                ),
              ),
              if (denied)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: PhotoManager.openSetting,
                    child: const Text('Open Settings'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ]),
    );
  }
}

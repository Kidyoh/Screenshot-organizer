import 'package:flutter/widgets.dart';

import '../app/prefs.dart';
import '../data/library.dart';

/// Makes the [Library] available below and rebuilds dependents on change.
class LibraryScope extends InheritedNotifier<Library> {
  const LibraryScope({super.key, required Library library, required super.child})
      : super(notifier: library);

  static Library of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LibraryScope>()!.notifier!;

  /// Without subscribing to changes (for callbacks).
  static Library read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LibraryScope>()!.notifier!;
}

class PrefsScope extends InheritedNotifier<Prefs> {
  const PrefsScope({super.key, required Prefs prefs, required super.child})
      : super(notifier: prefs);

  static Prefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrefsScope>()!.notifier!;
}

/// Lets a tab hide the floating nav bar (while it shows its selection dock).
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.navHidden, required super.child});

  final ValueNotifier<bool> navHidden;

  static ShellScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

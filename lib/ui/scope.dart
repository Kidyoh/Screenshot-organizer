import 'package:flutter/widgets.dart';

import '../data/library.dart';

/// Makes the [Library] available to the widget tree and rebuilds dependents
/// whenever it changes.
class LibraryScope extends InheritedNotifier<Library> {
  const LibraryScope({super.key, required Library library, required super.child})
      : super(notifier: library);

  static Library of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LibraryScope>()!.notifier!;

  /// Like [of] but without subscribing to changes (for callbacks).
  static Library read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LibraryScope>()!.notifier!;
}

const brandGradient = LinearGradient(
  colors: [Color(0xFF7B5CFF), Color(0xFFFF5E8E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

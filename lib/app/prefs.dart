import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App settings that aren't about the screenshots themselves.
class Prefs extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      themeMode = ThemeMode.values[p.getInt('themeMode') ?? 0];
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('themeMode', mode.index);
    } catch (_) {}
  }
}

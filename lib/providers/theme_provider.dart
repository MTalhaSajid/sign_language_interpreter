import 'package:flutter/material.dart';
import '../core/config/app_constants.dart';
import '../services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// Call once after [LocalStorageService.init()] in main.dart.
  Future<void> init() async {
    final saved = LocalStorageService.getBool(AppConstants.kThemeKey);
    _themeMode = saved ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await LocalStorageService.saveBool(
      AppConstants.kThemeKey,
      _themeMode == ThemeMode.dark,
    );
    notifyListeners();
  }
}

import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  // Thin controller. Theme toggling is delegated to ThemeProvider.
  // Extend here for: language preference, font size, notification settings, etc.

  String appVersion = '1.0.0';
  String appName = 'Sign Talk';

  Future<void> loadAppInfo() async {
    // package_info_plus can be used here if needed:
    // final info = await PackageInfo.fromPlatform();
    // appVersion = info.version;
    notifyListeners();
  }
}
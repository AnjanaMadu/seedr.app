import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _tokenKey = 'seedr_token';
  static const String _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  String? get token => _prefs.getString(_tokenKey);

  Future<void> setToken(String? token) async {
    if (token == null) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, token);
    }
    notifyListeners();
  }

  ThemeMode get themeMode {
    final mode = _prefs.getString(_themeKey);
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  bool get isLoggedIn => token != null;

  Future<void> logout() async {
    await setToken(null);
  }
}

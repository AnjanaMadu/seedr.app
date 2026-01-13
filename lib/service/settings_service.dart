import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _tokenKey = 'seedr_token';
  static const String _refreshTokenKey = 'seedr_refresh_token';
  static const String _themeKey = 'theme_mode';

  static const String _savedAccountsKey = 'saved_accounts';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  String? get token => _prefs.getString(_tokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);

  Future<void> setTokens(String? access, String? refresh) async {
    if (access == null) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, access);
    }

    if (refresh == null) {
      await _prefs.remove(_refreshTokenKey);
    } else {
      await _prefs.setString(_refreshTokenKey, refresh);
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

  bool get autoRefresh => _prefs.getBool('auto_refresh') ?? true;

  Future<void> setAutoRefresh(bool value) async {
    await _prefs.setBool('auto_refresh', value);
    notifyListeners();
  }

  bool get isLoggedIn => token != null;

  Future<void> logout() async {
    await setTokens(null, null);
  }

  List<Map<String, String>> get savedAccounts {
    final jsonString = _prefs.getString(_savedAccountsKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> list = json.decode(jsonString);
      return list.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveAccount(String username, String password) async {
    final accounts = savedAccounts;
    // Remove existing if any to update it
    accounts.removeWhere((acc) => acc['username'] == username);
    accounts.add({'username': username, 'password': password});
    await _prefs.setString(_savedAccountsKey, json.encode(accounts));
    notifyListeners();
  }

  Future<void> removeAccount(String username) async {
    final accounts = savedAccounts;
    accounts.removeWhere((acc) => acc['username'] == username);
    await _prefs.setString(_savedAccountsKey, json.encode(accounts));
    notifyListeners();
  }
}

// lib/core/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // ── Language ──────────────────────────────────────────────
  String getLanguage() => _prefs.getString(AppConstants.prefLanguage) ?? 'en';

  Future<void> setLanguage(String code) =>
      _prefs.setString(AppConstants.prefLanguage, code);

  // ── Theme ─────────────────────────────────────────────────
  bool isDarkMode() => _prefs.getBool(AppConstants.prefThemeMode) ?? false;

  Future<void> setDarkMode(bool value) =>
      _prefs.setBool(AppConstants.prefThemeMode, value);

  // ── First Launch ──────────────────────────────────────────
  bool isFirstLaunch() => _prefs.getBool(AppConstants.prefFirstLaunch) ?? true;

  Future<void> setFirstLaunchDone() =>
      _prefs.setBool(AppConstants.prefFirstLaunch, false);

  // ── Generic ───────────────────────────────────────────────
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> remove(String key) => _prefs.remove(key);
}
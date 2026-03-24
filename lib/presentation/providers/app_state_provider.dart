// lib/presentation/providers/app_state_provider.dart

import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/storage_service.dart';

class AppStateProvider extends ChangeNotifier {
  final StorageService _storageService = sl<StorageService>();

  bool _isDarkMode = false;
  bool _isOnline = true;
  String _currentLangCode = 'en';

  bool get isDarkMode => _isDarkMode;
  bool get isOnline => _isOnline;
  String get currentLangCode => _currentLangCode;
  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    _isDarkMode = _storageService.isDarkMode();
    _currentLangCode = _storageService.getLanguage();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _storageService.setDarkMode(value);
    notifyListeners();
  }

  void setOnlineStatus(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  Future<void> onLanguageChanged(String langCode) async {
    _currentLangCode = langCode;
    notifyListeners();
  }
}
// lib/features/multilingual/providers/language_provider.dart

import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../localization/app_localization.dart';

class LanguageProvider extends ChangeNotifier {
  final StorageService _storageService = sl<StorageService>();

  Locale _locale = const Locale('en');
  String _langCode = 'en';

  Locale get locale => _locale;
  String get langCode => _langCode;
  String get languageName => AppConstants.languageNames[_langCode] ?? 'English';

  Future<void> init() async {
    final saved = _storageService.getLanguage();
    await _applyLanguage(saved);
  }

  Future<void> setLanguage(String code) async {
    await _storageService.setLanguage(code);
    await _applyLanguage(code);
  }

  Future<void> _applyLanguage(String code) async {
    _langCode = code;
    // Keep the static activeLangCode in sync so AppLocalization
    // knows to load 'pidgin.json' even when Locale is 'en'.
    AppLocalization.activeLangCode = code;

    // Pidgin uses 'en' locale (no ISO 639 code for Nigerian Pidgin).
    _locale = Locale(code == 'pidgin' ? 'en' : code);
    notifyListeners();
  }

  bool isSelected(String code) => _langCode == code;
}
// lib/features/multilingual/providers/language_provider.dart

import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';

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
    if (!AppConstants.supportedLocales.contains(code)) {
      code = 'en';
    }

    _langCode = code;
    switch (code) {
      case 'yo':
        _locale = const Locale.fromSubtags(languageCode: 'en', countryCode: 'BJ');
        break;
      case 'ig':
        _locale = const Locale.fromSubtags(languageCode: 'en', countryCode: 'GH');
        break;
      case 'pidgin':
        _locale = const Locale.fromSubtags(languageCode: 'en', countryCode: 'PG');
        break;
      default:
        _locale = const Locale('en');
        break;
    }

    notifyListeners();
  }

  bool isSelected(String code) => _langCode == code;
}

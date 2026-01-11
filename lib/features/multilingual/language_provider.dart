import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage);  // Add this getter

  void changeLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }

  // You can expand this with translation logic
  String translate(String key) {
    // Add your translation logic here
    return key;
  }
}
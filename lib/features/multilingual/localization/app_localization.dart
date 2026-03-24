// lib/features/multilingual/localization/app_localization.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';

class AppLocalization {
  final Locale locale;
  final String _langCode;
  Map<String, String> _strings = {};

  // Holds the TRUE selected lang code (e.g. 'pidgin') even when
  // Flutter's Locale maps it to 'en' for system compatibility.
  static String activeLangCode = 'en';

  AppLocalization(this.locale, this._langCode);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  static const LocalizationsDelegate<AppLocalization> delegate =
  _AppLocalizationDelegate();
  Future<void> load() async {
    // Use activeLangCode (the real one) not locale.languageCode
    final targetCode = _langCode == 'en' ? activeLangCode : _langCode;

    try {
      final jsonString = await rootBundle.loadString(
        '${AppConstants.langBasePath}$targetCode.json',
      );

      // Fixed: Cast the dynamic result as a Map<String, dynamic> 👇
      final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _strings = jsonMap.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      // Fallback to English if target lang file fails
      try {
        final jsonString = await rootBundle.loadString(
          '${AppConstants.langBasePath}en.json',
        );

        // Fixed: Cast the dynamic result here too 👇
        final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        _strings = jsonMap.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _strings = {};
      }
    }
  }

  String translate(String key) => _strings[key] ?? key;
  String t(String key) => translate(key);

  // Translate with interpolation: tArgs('hello_name', {'name': 'Tunde'})
  String tArgs(String key, Map<String, String> args) {
    String result = translate(key);
    args.forEach((k, v) => result = result.replaceAll('{$k}', v));
    return result;
  }
}

// ── Extension for easy access ─────────────────────────────
extension LocalizationExtension on BuildContext {
  String t(String key) => AppLocalization.of(this).t(key);
  String tArgs(String key, Map<String, String> args) =>
      AppLocalization.of(this).tArgs(key, args);
}

// ── Delegate ──────────────────────────────────────────────
class _AppLocalizationDelegate
    extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    // 'en' covers both English and Pidgin (no official Pidgin locale code)
    const supported = ['en', 'yo', 'ig'];
    return supported.contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    final localization = AppLocalization(locale, locale.languageCode);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_AppLocalizationDelegate old) => true;
}
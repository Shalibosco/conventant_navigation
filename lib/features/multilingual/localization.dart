import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'title': 'Covenant Navigator',
      'subtitle': 'Your campus guide',
    },
    'yo': {
      'title': 'Covenant Navigator',
      'subtitle': 'Onimọran ile-ẹkọ rẹ',
    },
    'ig': {
      'title': 'Covenant Navigator',
      'subtitle': 'Onye nduzi ụlọ akwụkwọ gị',
    },
  };

  String get title {
    return _localizedStrings[locale.languageCode]?['title'] ?? 'Covenant Navigator';
  }

  String get subtitle {
    return _localizedStrings[locale.languageCode]?['subtitle'] ?? 'Your campus guide';
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'yo', 'ig'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
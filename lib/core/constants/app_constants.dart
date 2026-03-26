// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ── App ───────────────────────────────────────────────────
  static const String appName        = 'CU Navigate';
  static const String appVersion     = '1.0.0';
  static const String universityName = 'Covenant University';
  static const String universityAddr = 'Ota, Ogun State, Nigeria';

  // ── Google Maps API Key ───────────────────────────────────
  // Replace with your actual key from console.cloud.google.com
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // ── Campus Centre (geometric centre of all 33 landmarks) ──
  static const double campusLat  = 6.672639;
  static const double campusLng  = 3.157639;
  static const double defaultZoom = 16.5;
  static const double minZoom     = 14.0;
  static const double maxZoom     = 19.0;

  // ── Campus Boundary ───────────────────────────────────────
  static const double campusBoundNorth = 6.679611;
  static const double campusBoundSouth = 6.665667;
  static const double campusBoundEast  = 3.163500;
  static const double campusBoundWest  = 3.151778;

  // ── Languages ─────────────────────────────────────────────
  static const List<String> supportedLocales = ['en','yo','ig','pidgin'];
  static const Map<String, String> languageNames = {
    'en':     'English',
    'yo':     'Yorùbá',
    'ig':     'Igbo',
    'pidgin': 'Nigerian Pidgin',
  };
  static const Map<String, String> ttsLanguageCodes = {
    'en': 'en-NG', 'yo': 'yo', 'ig': 'ig', 'pidgin': 'en-NG',
  };
  static const Map<String, String> sttLanguageCodes = {
    'en': 'en_NG', 'yo': 'yo_NG', 'ig': 'ig_NG', 'pidgin': 'en_NG',
  };

  // ── Storage ───────────────────────────────────────────────
  static const String locationsBox  = 'locations_box';
  static const String settingsBox   = 'settings_box';
  static const String prefLanguage  = 'pref_language';
  static const String prefTheme     = 'pref_theme_mode';
  static const String prefFirstLaunch = 'pref_first_launch';

  // ── Assets ────────────────────────────────────────────────
  static const String locationsJsonPath = 'assets/map/covenant_locations.json';
  static const String langBasePath      = 'assets/lang/';

  // ── Categories ────────────────────────────────────────────
  static const String catAcademic   = 'academic';
  static const String catHostel     = 'hostel';
  static const String catWorship    = 'worship';
  static const String catFood       = 'food';
  static const String catSports     = 'sports';
  static const String catAdmin      = 'admin';
  static const String catMedical    = 'medical';
  static const String catRecreation = 'recreation';

  // ── Voice ─────────────────────────────────────────────────
  static const int    voiceListenSeconds     = 6;
  static const double voiceConfidenceThreshold = 0.7;

  // ── UI ────────────────────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 16.0;
  static const double radiusLg  = 24.0;
  static const double padSm     = 8.0;
  static const double padMd     = 16.0;
  static const double padLg     = 24.0;

  // ── Dark Map Style ────────────────────────────────────────
  static const String darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a1628"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8fa3c0"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a1628"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a3050"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0a1628"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8fa3c0"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#061020"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#0f1e33"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#0f1e33"}]}
]
''';
}



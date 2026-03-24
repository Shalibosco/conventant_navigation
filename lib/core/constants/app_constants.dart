// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────
  static const String appName = 'CU Navigate';
  static const String appVersion = '1.0.0';
  static const String universityName = 'Covenant University';
  static const String universityAddress = 'Ota, Ogun State, Nigeria';

  // ── Campus Coordinates (Center of Covenant University) ───
  static const double campusLat = 6.6722;
  static const double campusLng = 3.1600;
  static const double defaultZoom = 16.5;
  static const double minZoom = 14.0;
  static const double maxZoom = 19.0;

  // ── Campus Boundary (rough bounding box) ─────────────────
  static const double campusBoundNorth = 6.6780;
  static const double campusBoundSouth = 6.6660;
  static const double campusBoundEast = 3.1680;
  static const double campusBoundWest = 3.1520;

  // ── Supported Languages ───────────────────────────────────
  static const List<String> supportedLocales = ['en', 'yo', 'ig', 'pidgin'];
  static const Map<String, String> languageNames = {
    'en': 'English',
    'yo': 'Yorùbá',
    'ig': 'Igbo',
    'pidgin': 'Nigerian Pidgin',
  };

  // ── TTS Language Codes ────────────────────────────────────
  static const Map<String, String> ttsLanguageCodes = {
    'en': 'en-NG',
    'yo': 'yo',
    'ig': 'ig',
    'pidgin': 'en-NG',
  };

  // ── STT Language Codes ────────────────────────────────────
  static const Map<String, String> sttLanguageCodes = {
    'en': 'en_NG',
    'yo': 'yo_NG',
    'ig': 'ig_NG',
    'pidgin': 'en_NG',
  };

  // ── Hive Box Names ────────────────────────────────────────
  static const String locationsBox = 'locations_box';
  static const String infoBox = 'info_box';
  static const String settingsBox = 'settings_box';

  // ── Asset Paths ───────────────────────────────────────────
  static const String locationsJsonPath = 'assets/map/covenant_locations.json';
  static const String langBasePath = 'assets/lang/';

  // ── Shared Preferences Keys ───────────────────────────────
  static const String prefLanguage = 'pref_language';
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefFirstLaunch = 'pref_first_launch';

  // ── Location Categories ───────────────────────────────────
  static const String catAcademic = 'academic';
  static const String catHostel = 'hostel';
  static const String catWorship = 'worship';
  static const String catFood = 'food';
  static const String catSports = 'sports';
  static const String catAdmin = 'admin';
  static const String catMedical = 'medical';
  static const String catRecreation = 'recreation';

  // ── Map Tile URL ──────────────────────────────────────────
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String tileUserAgent = 'covenant_navigation/1.0.0';
  static const int tileCacheDays = 30;

  // ── Voice Assistant ───────────────────────────────────────
  static const int voiceListenDurationSeconds = 5;
  static const double voiceConfidenceThreshold = 0.7;

  // ── UI ────────────────────────────────────────────────────
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
}
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/network_service.dart';

import 'data/models/location_model.dart';

import 'features/multilingual/localization/app_localization.dart';
import 'features/multilingual/providers/language_provider.dart';
import 'features/navigation/providers/navigation_provider.dart';
import 'features/voice_assistant/providers/voice_provider.dart';
import 'presentation/providers/app_state_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Hive Init ────────────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(LocationModelAdapter());

  // ── Dependency Injection ─────────────────────────────────
  await initServiceLocator();

  // ── Run App ──────────────────────────────────────────────
  runApp(const CUNavigateApp());
}

class CUNavigateApp extends StatefulWidget {
  const CUNavigateApp({super.key});

  @override
  State<CUNavigateApp> createState() => _CUNavigateAppState();
}

class _CUNavigateAppState extends State<CUNavigateApp> {
  late final AppStateProvider _appStateProvider;
  late final LanguageProvider _languageProvider;
  late final NavigationProvider _navigationProvider;
  late final VoiceProvider _voiceProvider;

  @override
  void initState() {
    super.initState();
    _appStateProvider = AppStateProvider();
    _languageProvider = LanguageProvider();
    _navigationProvider = NavigationProvider();
    _voiceProvider = VoiceProvider();
    _initApp();
  }

  Future<void> _initApp() async {
    await _appStateProvider.init();
    await _languageProvider.init();

    // Monitor network connectivity
    sl<NetworkService>().connectivityStream.listen((isOnline) {
      _appStateProvider.setOnlineStatus(isOnline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appStateProvider),
        ChangeNotifierProvider.value(value: _languageProvider),
        ChangeNotifierProvider.value(value: _navigationProvider),
        ChangeNotifierProvider.value(value: _voiceProvider),
      ],
      child: Consumer2<AppStateProvider, LanguageProvider>(
        builder: (context, appState, langProvider, _) {
          return MaterialApp(
            // ── App Identity ──────────────────────────────
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // ── Theme ─────────────────────────────────────
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,

            // ── Routing ───────────────────────────────────
            initialRoute: AppRoutes.map,
            onGenerateRoute: AppRouter.generateRoute,

            // ── Localization ──────────────────────────────
            locale: langProvider.locale,
            supportedLocales: AppConstants.supportedLocales
                .map((code) => Locale(code == 'pidgin' ? 'en' : code))
                .toSet()
                .toList(),
            localizationsDelegates: const [
              AppLocalization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale?.languageCode) {
                  return supported;
                }
              }
              return const Locale('en');
            },

            // ── Builder: connectivity banner ──────────────
            builder: (context, child) {
              return Consumer<AppStateProvider>(
                builder: (context, appState, _) {
                  return Stack(
                    children: [
                      child!,
                      if (!appState.isOnline)
                        Positioned(
                          top: MediaQuery.of(context).padding.top,
                          left: 0,
                          right: 0,
                          child: _OfflineBanner(),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ── Offline Banner ────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: const Color(0xFFE67E22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            'Offline — Using cached map data',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
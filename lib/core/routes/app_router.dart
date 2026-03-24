// lib/core/routes/app_router.dart

import 'package:flutter/material.dart';
import '../../features/navigation/screens/map_screen.dart';
import '../../features/information/screens/info_screen.dart';
import '../../features/voice_assistant/screens/voice_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String map = '/';
  static const String info = '/info';
  static const String voice = '/voice';
  static const String settings = '/settings';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.map:
        return _fadeRoute(const MapScreen(), settings);

      case AppRoutes.info:
        return _slideRoute(const InfoScreen(), settings);

      case AppRoutes.voice:
        return _slideRoute(const VoiceScreen(), settings);

      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen(), settings);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route found for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
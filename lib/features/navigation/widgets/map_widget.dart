// lib/features/navigation/widgets/map_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

// 🟢 Define the Enum here so Dart knows what it is!
enum MapEngineType { google, osm }

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    // ── Build OpenStreetMap Viewport (Default) ───────────
    return MapViewTypeOsm(navProvider: navProvider);
  }
}

class MapViewTypeGoogle extends StatelessWidget {
  final NavigationProvider navProvider;
  const MapViewTypeGoogle({super.key, required this.navProvider});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class MapViewTypeOsm extends StatelessWidget {
  final NavigationProvider navProvider;
  const MapViewTypeOsm({super.key, required this.navProvider});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
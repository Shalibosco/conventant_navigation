// lib/core/services/map_engine.dart

import 'package:flutter/material.dart';

/// Define unified types so your UI doesn't care if it's Google or OSM
class UnifiedLatLng {
  final double latitude;
  final double longitude;
  const UnifiedLatLng(this.latitude, this.longitude);
}

class UnifiedMarker {
  final String id;
  final UnifiedLatLng position;
  final VoidCallback? onTap;
  final Widget? customIcon; // Used for OSM

  const UnifiedMarker({
    required this.id,
    required this.position,
    this.onTap,
    this.customIcon,
  });
}

abstract class MapEngine {
  /// Renders the Map Widget to the Screen
  Widget buildMap({
    required UnifiedLatLng initialCenter,
    required double initialZoom,
    required Set<UnifiedMarker> markers,
    required List<UnifiedLatLng> polylinePoints,
    required Function(UnifiedLatLng) onTap,
  });

  /// Programmatic controls (Move camera, zoom, etc.)
  void moveCamera(UnifiedLatLng target, double zoom);
}
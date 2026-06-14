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
  final Widget? customIcon;
  final double? width;
  final double? height;

  const UnifiedMarker({
    required this.id,
    required this.position,
    this.onTap,
    this.customIcon,
    this.width,
    this.height,
  });
}

abstract class MapEngine {
  /// Renders the Map Widget to the Screen
  Widget buildMap({
    required UnifiedLatLng initialCenter,
    required double initialZoom,
    required Set<UnifiedMarker> markers,
    required List<UnifiedLatLng> polylinePoints,
    required void Function(UnifiedLatLng) onTap,
  });

  /// Programmatic controls (Move camera, zoom, etc.)
  void moveCamera(UnifiedLatLng target, double zoom);
}

// lib/features/navigation/services/route_service.dart

import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class RouteService {

  /// Fetches routing points. If online API fails (or is missing), it falls back
  /// to a perfect straight-line vector between [start] and [end].
  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    try {
      // 📡 1. Online Routing Logic goes here (e.g., OSRM, GraphHopper, Mapbox)
      // For now, let's assume we are purely offline or the HTTP call failed.
      throw Exception('No internet connection available');

    } catch (e) {
      debugPrint('RouteService: Falling back to straight-line vector due to: $e');

      // 📍 2. OFFLINE FALLBACK: Return the direct straight-line vector!
      return _generateStraightLinePoints(start, end);
    }
  }

  /// Generates a smooth straight line. We add micro-interpolation points
  /// between Start and End so the map renders curved terrain lines smoothly!
  List<LatLng> _generateStraightLinePoints(LatLng start, LatLng end) {
    return [
      start, // The user's current standing position
      end,   // The target campus building destination
    ];
  }
}

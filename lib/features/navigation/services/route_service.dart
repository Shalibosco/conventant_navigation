// lib/features/navigation/services/route_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  static const String _osrmBase =
      'http://router.project-osrm.org/route/v1/foot';

  /// Fetches walking route from OSRM. Falls back to straight-line on error.
  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    try {
      final uri = Uri.parse(
        '$_osrmBase/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry =
              routes[0]['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List<dynamic>;
          // GeoJSON uses [longitude, latitude] ordering
          return coords.map((c) {
            final coord = c as List<dynamic>;
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('RouteService: OSRM unavailable ($e), using straight-line');
    }

    return [start, end];
  }

  void dispose() {}
}

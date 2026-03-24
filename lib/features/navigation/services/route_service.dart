// lib/features/navigation/services/route_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/error/exceptions.dart';

class RouteService {
  // Uses OSRM public API (free, no key required, works for walking)
  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/foot';

  Future<List<LatLng>> getWalkingRoute(LatLng from, LatLng to) async {
    try {
      final url = '$_osrmBaseUrl/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson&steps=false';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'covenant_navigation/1.0.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw NetworkException('Route service returned ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>;

      if (routes.isEmpty) {
        throw const NetworkException('No route found');
      }

      final geometry =
      routes[0]['geometry']['coordinates'] as List<dynamic>;

      return geometry
          .map((coord) {
        final c = coord as List<dynamic>;
        return LatLng(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        );
      })
          .toList();
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to get route: $e');
    }
  }

  // Straight-line fallback route when offline
  List<LatLng> getStraightLineRoute(LatLng from, LatLng to) {
    // Interpolate 10 points between from and to
    final points = <LatLng>[];
    const steps = 10;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      ));
    }
    return points;
  }
}
// lib/features/navigation/services/route_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  static const String _osrmBase =
      'https://router.project-osrm.org/route/v1/foot';
  static const double _rerouteDistanceThresholdMeters = 22;
  static const double _rerouteHeadingThresholdDegrees = 120;

  final bool preferOnlineRoutes;

  const RouteService({this.preferOnlineRoutes = true});

  /// Fetches walking route from OSRM. Falls back to straight-line on error.
  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    if (!preferOnlineRoutes) {
      return _straightLineRoute(start, end);
    }

    try {
      final uri = Uri.parse(
        '$_osrmBase/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>;
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

    return _straightLineRoute(start, end);
  }

  double distanceToRoute(LatLng point, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return double.infinity;
    if (routePoints.length == 1) {
      return const Distance().as(LengthUnit.Meter, point, routePoints.first);
    }

    var shortestDistance = double.infinity;
    for (var i = 0; i < routePoints.length - 1; i++) {
      final distance = _distanceToSegment(
        point,
        routePoints[i],
        routePoints[i + 1],
      );
      if (distance < shortestDistance) {
        shortestDistance = distance;
      }
    }
    return shortestDistance;
  }

  bool shouldReroute({
    required LatLng currentLocation,
    required List<LatLng> routePoints,
    required double? heading,
  }) {
    if (routePoints.length < 2) return false;

    final offRouteDistance = distanceToRoute(currentLocation, routePoints);
    if (offRouteDistance > _rerouteDistanceThresholdMeters) {
      return true;
    }

    if (heading == null) return false;

    final nextPoint = _nextRoutePoint(currentLocation, routePoints);
    if (nextPoint == null) return false;

    final routeBearing = const Distance().bearing(currentLocation, nextPoint);
    return _angleDifference(heading, routeBearing) >
        _rerouteHeadingThresholdDegrees;
  }

  List<LatLng> _straightLineRoute(LatLng start, LatLng end) {
    return [start, end];
  }

  double _distanceToSegment(LatLng point, LatLng start, LatLng end) {
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng =
        metersPerDegreeLat *
        math.cos(((start.latitude + end.latitude) / 2) * math.pi / 180);

    final px = point.longitude * metersPerDegreeLng;
    final py = point.latitude * metersPerDegreeLat;
    final sx = start.longitude * metersPerDegreeLng;
    final sy = start.latitude * metersPerDegreeLat;
    final ex = end.longitude * metersPerDegreeLng;
    final ey = end.latitude * metersPerDegreeLat;

    final dx = ex - sx;
    final dy = ey - sy;
    if (dx == 0 && dy == 0) {
      return const Distance().as(LengthUnit.Meter, point, start);
    }

    final projection =
        (((px - sx) * dx) + ((py - sy) * dy)) / ((dx * dx) + (dy * dy));
    final clampedProjection = projection.clamp(0.0, 1.0);
    final closestX = sx + (clampedProjection * dx);
    final closestY = sy + (clampedProjection * dy);

    final offsetX = px - closestX;
    final offsetY = py - closestY;
    return math.sqrt((offsetX * offsetX) + (offsetY * offsetY));
  }

  LatLng? _nextRoutePoint(LatLng currentLocation, List<LatLng> routePoints) {
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    const distance = Distance();

    for (var i = 0; i < routePoints.length; i++) {
      final currentDistance = distance.as(
        LengthUnit.Meter,
        currentLocation,
        routePoints[i],
      );
      if (currentDistance < nearestDistance) {
        nearestDistance = currentDistance;
        nearestIndex = i;
      }
    }

    if (nearestIndex >= routePoints.length - 1) {
      return routePoints.last;
    }
    return routePoints[nearestIndex + 1];
  }

  double _angleDifference(double a, double b) {
    final diff = ((a - b + 540) % 360) - 180;
    return diff.abs();
  }

  void dispose() {}
}

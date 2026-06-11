// lib/features/navigation/services/route_service.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ── Route result ──────────────────────────────────────────────────────────────

/// Holds the decoded route together with OSRM metadata.
class RouteResult {
  final List<LatLng> points;

  /// Total route distance in metres (from OSRM, or straight-line estimate).
  final double distanceMeters;

  /// Estimated travel duration in seconds (from OSRM, or 0 for fallback).
  final double durationSeconds;

  /// True when the route was computed by OSRM; false for straight-line fallback.
  final bool isOnlineRoute;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isOnlineRoute,
  });

  double get distanceKm => distanceMeters / 1000;
  Duration get duration => Duration(seconds: durationSeconds.round());
}

// ── Service ───────────────────────────────────────────────────────────────────

class RouteService {
  // ── Config ────────────────────────────────────────────────
  final String osrmBaseUrl;
  final bool preferOnlineRoutes;
  final double rerouteDistanceThresholdMeters;
  final double rerouteHeadingThresholdDegrees;

  // ── HTTP ──────────────────────────────────────────────────
  final http.Client _httpClient;

  // ── Shared Distance instance ──────────────────────────────
  static const Distance _distance = Distance();

  // ── Current-segment tracking ──────────────────────────────
  // Tracks the last known nearest segment so searches scan forward
  // from there instead of re-scanning from the beginning each frame.
  int _lastNearestIndex = 0;

  RouteService({
    this.osrmBaseUrl = 'https://router.project-osrm.org/route/v1/foot',
    this.preferOnlineRoutes = true,
    this.rerouteDistanceThresholdMeters = 22,
    this.rerouteHeadingThresholdDegrees = 120,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  // ── Route fetching ────────────────────────────────────────

  /// Fetches a walking route from OSRM.
  /// Falls back to a straight-line [RouteResult] on any error.
  Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    if (!preferOnlineRoutes) return _straightLineResult(start, end);

    try {
      final uri = Uri.parse(
        '$osrmBaseUrl/${start.longitude},${start.latitude};'
            '${end.longitude},${end.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'CUNavigate/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List<dynamic>;
          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          // GeoJSON uses [longitude, latitude] ordering.
          final points = coords.map((c) {
            final coord = c as List<dynamic>;
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          _lastNearestIndex = 0; // reset progress tracker for new route
          return RouteResult(
            points: points,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            isOnlineRoute: true,
          );
        }
      }
    } catch (e) {
      debugPrint('RouteService: OSRM unavailable ($e), using straight-line');
    }

    return _straightLineResult(start, end);
  }

  // ── Off-route detection ───────────────────────────────────

  /// Returns the shortest perpendicular distance in metres from [point] to
  /// any segment of [routePoints].
  ///
  /// Searches forward from [_lastNearestIndex] with a small backward window
  /// so the scan is O(k) where k ≪ n on a normal journey.
  double distanceToRoute(LatLng point, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return double.infinity;
    if (routePoints.length == 1) {
      return _distance.as(LengthUnit.Meter, point, routePoints.first);
    }

    // Search a bounded window around the last known position.
    // Looking back 5 segments handles slight GPS jitter; forward 30 covers
    // a sprinting user between GPS ticks.
    final windowStart = (_lastNearestIndex - 5).clamp(0, routePoints.length - 2);
    final windowEnd = (_lastNearestIndex + 30).clamp(0, routePoints.length - 2);

    var shortest = double.infinity;
    var nearestSegment = _lastNearestIndex;

    for (var i = windowStart; i <= windowEnd; i++) {
      final d = _distanceToSegment(point, routePoints[i], routePoints[i + 1]);
      if (d < shortest) {
        shortest = d;
        nearestSegment = i;
      }
    }

    // If nearest is at window edge, fall back to full scan (junction / U-turn).
    if (nearestSegment == windowEnd && windowEnd < routePoints.length - 2) {
      for (var i = windowEnd + 1; i < routePoints.length - 1; i++) {
        final d = _distanceToSegment(point, routePoints[i], routePoints[i + 1]);
        if (d < shortest) {
          shortest = d;
          nearestSegment = i;
        }
      }
    }

    _lastNearestIndex = nearestSegment;
    return shortest;
  }

  /// Returns true if the user should be re-routed.
  ///
  /// Triggers when:
  ///  - The user is more than [rerouteDistanceThresholdMeters] from the route, OR
  ///  - The user's heading deviates more than [rerouteHeadingThresholdDegrees]
  ///    from the expected bearing AND [headingAccuracy] is within 45°.
  bool shouldReroute({
    required LatLng currentLocation,
    required List<LatLng> routePoints,
    required double? heading,
    double? headingAccuracy,
  }) {
    if (routePoints.length < 2) return false;

    final offRoute = distanceToRoute(currentLocation, routePoints);
    if (offRoute > rerouteDistanceThresholdMeters) return true;

    if (heading == null) return false;

    // Skip heading check when the compass reading is unreliable.
    if (headingAccuracy != null && headingAccuracy > 45) return false;

    final next = _nextRoutePoint(currentLocation, routePoints);
    if (next == null) return false;

    final routeBearing = _distance.bearing(currentLocation, next);
    return _angleDifference(heading, routeBearing) >
        rerouteHeadingThresholdDegrees;
  }

  /// Resets the segment-tracking index. Call this when a new route is loaded
  /// or navigation is restarted.
  void resetProgress() => _lastNearestIndex = 0;

  // ── Helpers ───────────────────────────────────────────────

  RouteResult _straightLineResult(LatLng start, LatLng end) {
    final dist = _distance.as(LengthUnit.Meter, start, end);
    return RouteResult(
      points: [start, end],
      distanceMeters: dist,
      durationSeconds: 0,
      isOnlineRoute: false,
    );
  }

  /// Perpendicular distance from [point] to the segment [start]→[end].
  ///
  /// Uses a flat-earth approximation scaled at the segment's midpoint latitude.
  /// Accurate to < 0.1 % error for segments under 1 km — sufficient for
  /// campus-scale navigation.
  double _distanceToSegment(LatLng point, LatLng start, LatLng end) {
    const metersPerDegreeLat = 111320.0;

    // Compute the lng scale once per segment at the midpoint latitude.
    final midLat = (start.latitude + end.latitude) / 2;
    final metersPerDegreeLng =
        metersPerDegreeLat * math.cos(midLat * math.pi / 180);

    final px = point.longitude * metersPerDegreeLng;
    final py = point.latitude * metersPerDegreeLat;
    final sx = start.longitude * metersPerDegreeLng;
    final sy = start.latitude * metersPerDegreeLat;
    final ex = end.longitude * metersPerDegreeLng;
    final ey = end.latitude * metersPerDegreeLat;

    final dx = ex - sx;
    final dy = ey - sy;

    // Degenerate segment (start == end) — return point-to-point distance.
    if (dx == 0 && dy == 0) {
      return _distance.as(LengthUnit.Meter, point, start);
    }

    final t = (((px - sx) * dx) + ((py - sy) * dy)) / (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0);
    final closestX = sx + clamped * dx;
    final closestY = sy + clamped * dy;

    return math.sqrt(
      math.pow(px - closestX, 2) + math.pow(py - closestY, 2),
    );
  }

  /// Returns the next waypoint along the route ahead of [currentLocation].
  ///
  /// Uses [_lastNearestIndex] so it doesn't re-scan from the beginning.
  LatLng? _nextRoutePoint(LatLng currentLocation, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return null;

    final nextIndex = _lastNearestIndex + 1;
    if (nextIndex >= routePoints.length) return routePoints.last;
    return routePoints[nextIndex];
  }

  double _angleDifference(double a, double b) =>
      (((a - b + 540) % 360) - 180).abs();

  // ── Cleanup ───────────────────────────────────────────────

  void dispose() {
    _httpClient.close();
  }
}
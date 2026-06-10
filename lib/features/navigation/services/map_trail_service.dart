// lib/features/navigation/services/map_trail_service.dart
// Tracks user movement and displays trail on map

import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class MapTrailService extends ChangeNotifier {
  final List<LatLng> _trailPoints = [];
  final int _maxTrailLength =
      500; // Keep last 500 points to avoid memory issues

  List<LatLng> get trailPoints => List.unmodifiable(_trailPoints);
  bool get hasTrail => _trailPoints.isNotEmpty;

  /// Add a location point to the trail
  void addTrailPoint(LatLng point) {
    if (_trailPoints.isEmpty ||
        _calculateDistance(_trailPoints.last, point) > 1) {
      // Only add if it's more than 1 meter away from the last point
      _trailPoints.add(point);

      // Keep trail bounded to prevent memory issues
      if (_trailPoints.length > _maxTrailLength) {
        _trailPoints.removeAt(0);
      }
      notifyListeners();
    }
  }

  /// Add multiple points to trail
  void addTrailPoints(List<LatLng> points) {
    for (final point in points) {
      addTrailPoint(point);
    }
  }

  /// Clear the trail
  void clearTrail() {
    _trailPoints.clear();
    notifyListeners();
  }

  /// Reset and start new trail
  void resetTrail(LatLng startPoint) {
    _trailPoints.clear();
    _trailPoints.add(startPoint);
    notifyListeners();
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(LatLng p1, LatLng p2) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  /// Get total trail distance in kilometers
  double getTotalTrailDistance() {
    if (_trailPoints.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < _trailPoints.length - 1; i++) {
      total += _calculateDistance(_trailPoints[i], _trailPoints[i + 1]);
    }
    return total / 1000; // Convert to km
  }

  @override
  void dispose() {
    _trailPoints.clear();
    super.dispose();
  }
}

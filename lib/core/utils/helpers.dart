import 'dart:math';
import 'package:latlong2/latlong.dart';
import '/core/app_constants.dart';  // Add this import

class Helpers {
  // Calculate distance between two coordinates in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371e3; // Earth's radius in meters
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) *
            sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  // Check if location is within campus radius
  static bool isWithinCampus(LatLng location) {
    final campusCenter = LatLng(
      AppConstants.campusLatitude,
      AppConstants.campusLongitude,
    );
    final distance = calculateDistance(location, campusCenter);
    return distance <= AppConstants.campusRadius;
  }

  // Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Get bearing between two points
  static double getBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final y = sin(endLng - startLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(endLng - startLng);

    var bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }
}
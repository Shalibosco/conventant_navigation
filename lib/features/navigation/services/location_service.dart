// lib/features/navigation/services/location_service.dart
import 'package:flutter/foundation.dart';  // Add this import for debugPrint
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/app_constants.dart';
import '../../../core/utils/helpers.dart';

class LocationService {
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return null;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        return null;
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LatLng(position.latitude, position.longitude);

      // Check if within campus
      if (Helpers.isWithinCampus(location)) {
        return location;
      } else {
        // Return campus center if outside
        return LatLng(
          AppConstants.campusLatitude,
          AppConstants.campusLongitude,
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');  // Now works with import
      return null;
    }
  }

  Future<String> getDirections(LatLng from, LatLng to) async {
    final distance = Helpers.calculateDistance(from, to);
    final bearing = Helpers.getBearing(from, to);

    String direction = '';
    if (bearing >= 337.5 || bearing < 22.5) {
      direction = 'North';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      direction = 'Northeast';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      direction = 'East';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      direction = 'Southeast';
    } else if (bearing >= 157.5 && bearing < 202.5) {
      direction = 'South';
    } else if (bearing >= 202.5 && bearing < 247.5) {
      direction = 'Southwest';
    } else if (bearing >= 247.5 && bearing < 292.5) {
      direction = 'West';
    } else {
      direction = 'Northwest';
    }

    return 'Head $direction for ${Helpers.formatDistance(distance)}';
  }

  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    return [from, to];
  }
}
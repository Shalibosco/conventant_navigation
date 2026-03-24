// lib/features/navigation/services/offline_map_service.dart

import 'package:latlong2/latlong.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/constants/app_constants.dart'; // Corrected path to include /constants/

class OfflineMapService {

  // 1. Fix: Extract latitude and longitude from the LatLng objects to pass 4 doubles
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Helpers.calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  Future<void> cacheMapTiles() async {
    // Download tiles for campus radius
    // Store in local database
  }

  Future<bool> isLocationWithinCampus(LatLng location) async {
    // 2. Fix: Match variables to your actual app_constants.dart
    final distance = _calculateDistance(
      location,
      const LatLng(
        AppConstants.campusLat, // Fixed name
        AppConstants.campusLng, // Fixed name
      ),
    );

    // Let's assume a 2500-meter threshold for bounding Hebron (approx 2.5km)
    const double campusRadiusThreshold = 2500.0;

    return distance <= campusRadiusThreshold;
  }
}
import 'package:latlong2/latlong.dart';
import '../../../core/utils/helpers.dart';  // Fixed: Two dots not three
import '../../../core/app_constants.dart';

class OfflineMapService {
  // Calculate distance method for this class
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Helpers.calculateDistance(point1, point2);
  }

  Future<void> cacheMapTiles() async {
    // Download tiles for campus radius (2373m)
    // Store in local database
  }

  Future<bool> isLocationWithinCampus(LatLng location) async {
    // Check if location is within 2373m radius
    final distance = _calculateDistance(
      location,
      LatLng(
        AppConstants.campusLatitude,
        AppConstants.campusLongitude,
      ),
    );
    return distance <= AppConstants.campusRadius;
  }
}
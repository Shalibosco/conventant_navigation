// lib/features/navigation/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/permissions_service.dart';
import '../../../core/error/exceptions.dart';

class LocationService {
  final PermissionsService _permissionsService;

  LocationService(this._permissionsService);

  Future<LatLng?> getCurrentLocation() async {
    try {
      await _permissionsService.requestLocationPermission();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LatLng(position.latitude, position.longitude);
    } on PermissionException {
      rethrow;
    } catch (e) {
      throw LocationException('Failed to get current location: $e');
    }
  }

  Stream<LatLng> trackLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // update every 3 meters
      ),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  Future<double> getBearing(LatLng from, LatLng to) async {
    final bearing = Geolocator.bearingBetween(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );
    return bearing;
  }

  Future<double> getDistanceBetween(LatLng from, LatLng to) async {
    return Geolocator.distanceBetween(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );
  }
}
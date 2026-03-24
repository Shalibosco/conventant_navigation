// lib/core/services/permissions_service.dart

import 'package:geolocator/geolocator.dart';
import '../error/exceptions.dart';

class PermissionsService {
  Future<bool> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const PermissionException(
        'Location services are disabled. Please enable GPS.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionException(
          'Location permission denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionException(
        'Location permission permanently denied. Please enable in settings.',
      );
    }

    return true;
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
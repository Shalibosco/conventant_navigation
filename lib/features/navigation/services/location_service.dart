// lib/features/navigation/services/location_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/permissions_service.dart';
import '../../../core/error/exceptions.dart';

class LocationService {
  final PermissionsService _permissionsService;

  LocationService(this._permissionsService);

  // ── Active tracking subscription ─────────────────────────
  StreamSubscription<Position>? _trackingSubscription;
  final StreamController<LatLng> _trackingController =
      StreamController<LatLng>.broadcast();

  // ── Public stream ─────────────────────────────────────────
  /// Emits the user's position whenever they move [distanceFilter] metres.
  /// Errors are forwarded as [LocationException]s so subscribers can react
  /// without crashing.
  Stream<LatLng> get locationStream => _trackingController.stream;

  // ── Single fix ────────────────────────────────────────────

  /// Returns the device's current position.
  ///
  /// If GPS takes longer than [timeout], falls back to the last known
  /// position before throwing a [LocationException].
  Future<LatLng?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await _ensurePermissionAndService();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      // GPS cold-start indoors: try last-known before giving up.
      return await _fallbackToLastKnown();
    } on PermissionException {
      rethrow;
    } catch (e) {
      // Try last-known as a graceful degradation before throwing.
      final fallback = await _fallbackToLastKnown();
      if (fallback != null) return fallback;
      throw LocationException('Failed to get current location: $e');
    }
  }

  /// Returns the last recorded position instantly (no GPS fix needed).
  /// Useful for seeding the map before a fresh fix arrives.
  Future<LatLng?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('LocationService: last known position unavailable — $e');
      return null;
    }
  }

  // ── Continuous tracking ───────────────────────────────────

  /// Starts streaming the user's location into [locationStream].
  ///
  /// [distanceFilter] — minimum metres of movement before a new point is
  /// emitted. Use a small value (3–5 m) for walking nav, larger (20+ m) for
  /// a static overview.
  ///
  /// Calling this while already tracking is a no-op.
  Future<void> startTracking({int distanceFilter = 3}) async {
    if (_trackingSubscription != null) return; // already tracking

    await _ensurePermissionAndService();

    _trackingSubscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: distanceFilter,
          ),
        ).listen(
          (Position pos) {
            if (!_trackingController.isClosed) {
              _trackingController.add(LatLng(pos.latitude, pos.longitude));
            }
          },
          onError: (Object error) {
            debugPrint('LocationService tracking error: $error');
            if (!_trackingController.isClosed) {
              _trackingController.addError(
                LocationException('Location tracking error: $error'),
              );
            }
          },
          cancelOnError: false, // keep stream alive after transient errors
        );
  }

  /// Stops streaming location updates and releases the platform subscription.
  Future<void> stopTracking() async {
    await _trackingSubscription?.cancel();
    _trackingSubscription = null;
  }

  // ── Calculations (sync — no async needed) ────────────────

  /// Returns the compass bearing in degrees from [from] to [to].
  double getBearing(LatLng from, LatLng to) => Geolocator.bearingBetween(
    from.latitude,
    from.longitude,
    to.latitude,
    to.longitude,
  );

  /// Returns the straight-line distance in metres between [from] and [to].
  double getDistanceBetween(LatLng from, LatLng to) =>
      Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

  // ── Permission + service guard ────────────────────────────

  /// Ensures location permission is granted and the device's location service
  /// is enabled before making any Geolocator call.
  Future<void> _ensurePermissionAndService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are disabled. '
        'Please enable GPS in your device settings.',
      );
    }
    await _permissionsService.requestLocationPermission();
  }

  // ── Last-known fallback ───────────────────────────────────
  Future<LatLng?> _fallbackToLastKnown() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      debugPrint('LocationService: using last known position as fallback.');
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  // ── Cleanup ───────────────────────────────────────────────
  Future<void> dispose() async {
    await stopTracking();
    await _trackingController.close();
  }
}

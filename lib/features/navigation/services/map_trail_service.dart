// lib/features/navigation/services/map_trail_service.dart
// Tracks user movement and displays trail on map

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class MapTrailService extends ChangeNotifier {
  // ── Configuration ─────────────────────────────────────────
  /// Maximum number of points retained in the trail.
  /// Older points are dropped when this is exceeded.
  final int maxTrailLength;

  /// Minimum distance in metres a new point must be from the last
  /// before it is accepted. Filters out GPS jitter.
  final double minDistanceMetres;

  MapTrailService({
    this.maxTrailLength = 500,
    this.minDistanceMetres = 1.0,
  });

  // ── Internal state ────────────────────────────────────────
  // Queue gives O(1) removeFirst (trim from front) vs List's O(n).
  final Queue<LatLng> _trail = Queue<LatLng>();

  // Incrementally maintained so getTotalTrailDistance() is O(1).
  double _totalDistanceMetres = 0.0;

  // Reused across all distance calculations — no per-call allocation.
  static const Distance _distance = Distance();

  // Cached unmodifiable view — rebuilt only when the trail changes.
  List<LatLng>? _cachedView;

  // ── Public getters ────────────────────────────────────────

  /// An unmodifiable snapshot of the trail, cached between mutations.
  List<LatLng> get trailPoints => _cachedView ??= List.unmodifiable(_trail);

  bool get hasTrail => _trail.isNotEmpty;

  /// Total trail distance in kilometres, maintained incrementally — O(1).
  double get totalDistanceKm => _totalDistanceMetres / 1000;

  // ── Mutation API ──────────────────────────────────────────

  /// Adds [point] to the trail if it is at least [minDistanceMetres] from
  /// the previous point (filters GPS jitter).
  void addTrailPoint(LatLng point) {
    if (_trail.isNotEmpty &&
        _dist(_trail.last, point) < minDistanceMetres) {
      return; // too close — skip without notifying
    }

    // Maintain incremental distance before trimming.
    if (_trail.isNotEmpty) {
      _totalDistanceMetres += _dist(_trail.last, point);
    }

    _trail.addLast(point);

    // Trim oldest point when over capacity.
    if (_trail.length > maxTrailLength) {
      // Subtract the distance the removed segment contributed.
      if (_trail.length >= 2) {
        final removed = _trail.first;
        _trail.removeFirst();
        _totalDistanceMetres -= _dist(removed, _trail.first);
        if (_totalDistanceMetres < 0) _totalDistanceMetres = 0;
      } else {
        _trail.removeFirst();
      }
    }

    _invalidateCache();
    notifyListeners();
  }

  /// Adds multiple points in a single batch, notifying listeners only once.
  void addTrailPoints(List<LatLng> points) {
    if (points.isEmpty) return;

    for (final point in points) {
      // Inline the filter + insert logic without calling notifyListeners each time.
      if (_trail.isNotEmpty &&
          _dist(_trail.last, point) < minDistanceMetres) {
        continue;
      }
      if (_trail.isNotEmpty) {
        _totalDistanceMetres += _dist(_trail.last, point);
      }
      _trail.addLast(point);

      if (_trail.length > maxTrailLength) {
        if (_trail.length >= 2) {
          final removed = _trail.first;
          _trail.removeFirst();
          _totalDistanceMetres -= _dist(removed, _trail.first);
          if (_totalDistanceMetres < 0) _totalDistanceMetres = 0;
        } else {
          _trail.removeFirst();
        }
      }
    }

    _invalidateCache();
    notifyListeners(); // single notification for the whole batch
  }

  /// Clears the trail and resets the distance counter.
  void clearTrail() {
    if (_trail.isEmpty) return; // no-op if already empty
    _trail.clear();
    _totalDistanceMetres = 0.0;
    _invalidateCache();
    notifyListeners();
  }

  /// Clears the trail and starts fresh from [startPoint].
  void resetTrail(LatLng startPoint) {
    _trail.clear();
    _totalDistanceMetres = 0.0;
    _trail.addLast(startPoint);
    _invalidateCache();
    notifyListeners();
  }

  /// Returns a plain `List<LatLng>` copy suitable for polyline rendering
  /// or export — independent of the internal cache.
  List<LatLng> toList() => _trail.toList(growable: false);

  // ── Helpers ───────────────────────────────────────────────

  double _dist(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Meter, a, b);

  void _invalidateCache() => _cachedView = null;

  // ── Cleanup ───────────────────────────────────────────────

  @override
  void dispose() {
    _trail.clear();
    _cachedView = null;
    super.dispose();
  }
}
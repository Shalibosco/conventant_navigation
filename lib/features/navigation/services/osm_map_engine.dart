// lib/features/navigation/services/osm_map_engine.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/services/map_engine.dart';

class OsmMapEngine implements MapEngine {
  // ── Controller ────────────────────────────────────────────
  // Exposed so callers (e.g. a StatefulWidget) can pass it into FlutterMap
  // and control its lifecycle. Created once; never recreated on rebuild.
  final osm.MapController controller = osm.MapController();

  /// Whether the map controller is ready to accept camera commands.
  bool _isReady = false;

  // ── Route style ───────────────────────────────────────────
  final Color routeColor;
  final double routeStrokeWidth;

  OsmMapEngine({
    this.routeColor = Colors.blue,
    this.routeStrokeWidth = 5.0,
  });

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget buildMap({
    required UnifiedLatLng initialCenter,
    required double initialZoom,
    required Set<UnifiedMarker> markers,
    required List<UnifiedLatLng> polylinePoints,
    required void Function(UnifiedLatLng) onTap,
  }) {
    return osm.FlutterMap(
      mapController: controller,
      options: osm.MapOptions(
        initialCenter: ll.LatLng(
          initialCenter.latitude,
          initialCenter.longitude,
        ),
        initialZoom: initialZoom,
        onTap: (_, point) =>
            onTap(UnifiedLatLng(point.latitude, point.longitude)),
        onMapReady: () => _isReady = true,
      ),
      children: [
        // ── Tile layer with loading + error placeholders ────
        osm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.covenant.navigation',
          maxNativeZoom: 19,
          keepBuffer: 4,
          // 🔧 Use tileBuilder to control the UI for each tile
          tileBuilder: (context, widget, tile) {
            // If the tile hasn't finished loading, show a placeholder
            if (tile.loadFinishedAt == null) {
              return const ColoredBox(color: Color(0xFFE8E8E8));
            }
            // If there was an error loading the tile, show an error icon
            if (tile.loadError) {
              return const Icon(Icons.broken_image, color: Colors.grey);
            }
            // Otherwise, return the standard tile widget
            return widget;
          },
        ),

        // ── Route polyline — only rendered when there are points ────
        if (polylinePoints.length >= 2)
          osm.PolylineLayer(
            polylines: [
              osm.Polyline(
                points: polylinePoints
                    .map((p) => ll.LatLng(p.latitude, p.longitude))
                    .toList(),
                color: routeColor,
                strokeWidth: routeStrokeWidth,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        // ── Markers — only rendered when there are markers ──
        if (markers.isNotEmpty)
          osm.MarkerLayer(
            markers: markers.map(_buildMarker).toList(),
          ),
      ],
    );
  }

  // ── Marker builder ────────────────────────────────────────
  osm.Marker _buildMarker(UnifiedMarker m) {
    const defaultSize = 40.0;
    return osm.Marker(
      point: ll.LatLng(m.position.latitude, m.position.longitude),
      width: m.width ?? defaultSize,
      height: m.height ?? defaultSize,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: m.onTap,
        child: m.customIcon ?? const Icon(Icons.location_on, color: Colors.red, size: defaultSize),
      ),
    );
  }
  // ── Camera ────────────────────────────────────────────────
  @override
  void moveCamera(UnifiedLatLng target, double zoom) {
    if (!_isReady) {
      debugPrint('OsmMapEngine: moveCamera called before map is ready — ignored.');
      return;
    }
    controller.move(ll.LatLng(target.latitude, target.longitude), zoom);
  }

  /// Animates the camera to [target] using a [AnimationController].
  /// Useful for smooth fly-to transitions when navigating to a location.
  void animateCamera({
    required UnifiedLatLng target,
    required double zoom,
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    if (!_isReady) return;

    final animController = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    final startLatLng = controller.camera.center;
    final startZoom = controller.camera.zoom;
    final endLatLng = ll.LatLng(target.latitude, target.longitude);

    final latTween = Tween<double>(
      begin: startLatLng.latitude,
      end: endLatLng.latitude,
    );
    final lngTween = Tween<double>(
      begin: startLatLng.longitude,
      end: endLatLng.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: zoom);
    final curve = CurvedAnimation(
      parent: animController,
      curve: Curves.easeInOut,
    );

    animController.addListener(() {
      controller.move(
        ll.LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });

    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animController.dispose();
      }
    });

    animController.forward();
  }

  // ── Cleanup ───────────────────────────────────────────────
  void dispose() {
    controller.dispose();
    _isReady = false;
  }
}
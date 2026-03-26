// lib/features/navigation/services/osm_map_engine.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/services/map_engine.dart';

class OsmMapEngine implements MapEngine {
  final osm.MapController _controller = osm.MapController();

  @override
  Widget buildMap({
    required UnifiedLatLng initialCenter,
    required double initialZoom,
    required Set<UnifiedMarker> markers,
    required List<UnifiedLatLng> polylinePoints,
    required Function(UnifiedLatLng) onTap,
  }) {
    return osm.FlutterMap(
      mapController: _controller,
      options: osm.MapOptions(
        initialCenter: ll.LatLng(initialCenter.latitude, initialCenter.longitude),
        initialZoom: initialZoom,
        onTap: (_, point) => onTap(UnifiedLatLng(point.latitude, point.longitude)),
      ),
      children: [
        osm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.convenant.navigation',
        ),
        osm.PolylineLayer(
          polylines: [
            osm.Polyline(
              points: polylinePoints.map((p) => ll.LatLng(p.latitude, p.longitude)).toList(),
              color: Colors.blue,
              strokeWidth: 5,
            ),
          ],
        ),
        osm.MarkerLayer(
          markers: markers.map((m) => osm.Marker(
            point: ll.LatLng(m.position.latitude, m.position.longitude),
            child: GestureDetector(
              onTap: m.onTap,
              child: m.customIcon ?? const Icon(Icons.location_on, color: Colors.red),
            ),
          )).toList(),
        ),
      ],
    );
  }

  @override
  void moveCamera(UnifiedLatLng target, double zoom) {
    _controller.move(ll.LatLng(target.latitude, target.longitude), zoom);
  }
}

// lib/features/navigation/services/google_map_engine.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../core/services/map_engine.dart';

class GoogleMapEngine implements MapEngine {
  gmaps.GoogleMapController? _controller;

  @override
  Widget buildMap({
    required UnifiedLatLng initialCenter,
    required double initialZoom,
    required Set<UnifiedMarker> markers,
    required List<UnifiedLatLng> polylinePoints,
    required Function(UnifiedLatLng) onTap,
  }) {
    return gmaps.GoogleMap(
      onMapCreated: (controller) => _controller = controller,
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(initialCenter.latitude, initialCenter.longitude),
        zoom: initialZoom,
      ),
      markers: markers.map((m) => gmaps.Marker(
        markerId: gmaps.MarkerId(m.id),
        position: gmaps.LatLng(m.position.latitude, m.position.longitude),
        onTap: m.onTap,
      )).toSet(),
      polylines: {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: polylinePoints.map((p) => gmaps.LatLng(p.latitude, p.longitude)).toList(),
          color: Colors.blue,
          width: 5,
        )
      },
      onTap: (latLng) => onTap(UnifiedLatLng(latLng.latitude, latLng.longitude)),
    );
  }

  @override
  void moveCamera(UnifiedLatLng target, double zoom) {
    _controller?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(target.latitude, target.longitude),
        zoom,
      ),
    );
  }
}
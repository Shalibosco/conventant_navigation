// lib/features/navigation/widgets/map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../services/local_first_tile_provider.dart';
import '../services/offline_map_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../presentation/providers/app_state_provider.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  
  const MapWidget({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final isDark = context.watch<AppStateProvider>().isDarkMode;
    final offlineMapService = sl<OfflineMapService>();
    final tileStyle = isDark ? 'dark' : 'light';

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: const LatLng(AppConstants.campusLat, AppConstants.campusLng),
        initialZoom: AppConstants.defaultZoom,
        maxZoom: AppConstants.maxZoom,
        minZoom: AppConstants.minZoom,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(
            const LatLng(AppConstants.campusBoundSouth, AppConstants.campusBoundWest),
            const LatLng(AppConstants.campusBoundNorth, AppConstants.campusBoundEast),
          ),
        ),
      ),
      children: [
        if (isDark)
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.covenant.campus_navigation',
            tileProvider: LocalFirstTileProvider(
              offlineMapService: offlineMapService,
              style: tileStyle,
            ),
          )
        else
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.covenant.campus_navigation',
            tileProvider: LocalFirstTileProvider(
              offlineMapService: offlineMapService,
              style: tileStyle,
            ),
          ),
        PolylineLayer(
          polylines: navProvider.osmPolylines,
        ),
        MarkerLayer(
          markers: navProvider.osmMarkers,
        ),
      ],
    );
  }
}

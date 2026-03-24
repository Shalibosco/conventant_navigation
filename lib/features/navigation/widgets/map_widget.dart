// lib/features/navigation/widgets/map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../../../data/models/location_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_theme.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;

  const MapWidget({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: navProvider.userLocation ?? Helpers.campusCenter,
        initialZoom: AppConstants.defaultZoom,
        minZoom: AppConstants.minZoom,
        maxZoom: AppConstants.maxZoom,
        onTap: (_, __) {},
      ),
      children: [
        // ── Tile Layer ──────────────────────────────────────
        TileLayer(
          urlTemplate: AppConstants.tileUrlTemplate,
          userAgentPackageName: AppConstants.tileUserAgent,
          maxZoom: AppConstants.maxZoom,
        ),

        // ── Route Polyline ──────────────────────────────────
        if (navProvider.hasRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: navProvider.routePoints,
                strokeWidth: 5.0,
                color: AppTheme.accentColor,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),

        // ── Location Markers ────────────────────────────────
        MarkerLayer(
          markers: [
            // All campus location markers
            ...navProvider.filteredLocations.map(
                  (loc) => _buildLocationMarker(context, loc, navProvider),
            ),

            // User location marker
            if (navProvider.userLocation != null)
              _buildUserMarker(navProvider.userLocation!),

            // Destination marker
            if (navProvider.selectedDestination != null)
              _buildDestinationMarker(navProvider.selectedDestination!),
          ],
        ),
      ],
    );
  }

  Marker _buildLocationMarker(
      BuildContext context,
      LocationModel location,
      NavigationProvider navProvider,
      ) {
    final isSelected = navProvider.selectedDestination?.id == location.id;
    final color = Helpers.getCategoryColor(location.category);

    return Marker(
      point: LatLng(location.latitude, location.longitude),
      width: isSelected ? 48 : 36,
      height: isSelected ? 48 : 36,
      child: GestureDetector(
        onTap: () => _onMarkerTap(context, location),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 3 : 1,
              ),
            ],
          ),
          child: Icon(
            Helpers.getCategoryIcon(location.category),
            color: Colors.white,
            size: isSelected ? 24 : 18,
          ),
        ),
      ),
    );
  }

  Marker _buildUserMarker(LatLng position) {
    return Marker(
      point: position,
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildDestinationMarker(LocationModel destination) {
    return Marker(
      point: LatLng(destination.latitude, destination.longitude),
      width: 52,
      height: 64,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.6),
                  blurRadius: 14,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.flag_rounded, color: Colors.white, size: 26),
          ),
          Container(width: 3, height: 12, color: AppTheme.accentColor),
        ],
      ),
    );
  }

  void _onMarkerTap(BuildContext context, LocationModel location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkerBottomSheet(location: location),
    );
  }
}

// ── Marker tap bottom sheet ────────────────────────────────
class _MarkerBottomSheet extends StatelessWidget {
  final LocationModel location;
  const _MarkerBottomSheet({required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navProvider = context.read<NavigationProvider>();
    final color = Helpers.getCategoryColor(location.category);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Helpers.getCategoryIcon(location.category),
                        color: color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location.name,
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              Helpers.capitalize(location.category),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: color, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(location.description, style: theme.textTheme.bodyMedium),
                if (location.openingHours != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 6),
                      Text(location.openingHours!,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      navProvider.navigateTo(location);
                    },
                    icon: const Icon(Icons.directions_walk_rounded),
                    label: const Text('Navigate Here'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
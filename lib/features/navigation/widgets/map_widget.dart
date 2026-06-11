// lib/features/navigation/widgets/map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../presentation/providers/app_state_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/offline_map_service.dart';
import '../services/local_first_tile_provider.dart' as tile_provider;

class MapWidget extends StatefulWidget {
  final MapController mapController;

  /// Called when the map is fully initialized and ready for camera commands.
  final VoidCallback? onMapReady;

  /// Called when the user taps the map.
  final void Function(LatLng position)? onTap;

  const MapWidget({
    super.key,
    required this.mapController,
    this.onMapReady,
    this.onTap,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late final OfflineMapService _offlineMapService;
  late final http.Client _httpClient;

  late final tile_provider.LocalFirstTileProvider _lightProvider;
  late final tile_provider.LocalFirstTileProvider _darkProvider;

  @override
  void initState() {
    super.initState();
    _offlineMapService = sl<OfflineMapService>();
    _httpClient = sl<http.Client>();

    _lightProvider = _buildProvider('light');
    _darkProvider = _buildProvider('dark');
  }

  tile_provider.LocalFirstTileProvider _buildProvider(String style) =>
      tile_provider.LocalFirstTileProvider(
        offlineMapService: _offlineMapService,
        httpClient: _httpClient,
        style: style,
      );

  @override
  void dispose() {
    _lightProvider.dispose();
    _darkProvider.dispose();
    super.dispose();
  }

  // ── Tile URL helpers ──────────────────────────────────────

  String _tileUrl(bool isDark) => isDark
      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
      : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

  List<String> _subdomains(bool isDark) =>
      isDark ? const ['a', 'b', 'c', 'd'] : const ['a', 'b', 'c'];

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Use select() to avoid rebuilding when unrelated AppStateProvider
    // fields change — only re-render when isDarkMode flips.
    final isDark = context.select<AppStateProvider, bool>((p) => p.isDarkMode);
    final navProvider = context.watch<NavigationProvider>();

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: const LatLng(
          AppConstants.campusLat,
          AppConstants.campusLng,
        ),
        initialZoom: AppConstants.defaultZoom,
        maxZoom: AppConstants.maxZoom,
        minZoom: AppConstants.minZoom,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(
            const LatLng(
              AppConstants.campusBoundSouth,
              AppConstants.campusBoundWest,
            ),
            const LatLng(
              AppConstants.campusBoundNorth,
              AppConstants.campusBoundEast,
            ),
          ),
        ),
        onMapReady: widget.onMapReady,
        onTap: widget.onTap != null ? (_, point) => widget.onTap!(point) : null,
      ),
      children: [
        // ── Tile layer — single definition, style-aware ─────
        TileLayer(
          urlTemplate: _tileUrl(isDark),
          subdomains: _subdomains(isDark),
          userAgentPackageName: 'com.covenant.campus_navigation',
          tileProvider: isDark ? _darkProvider : _lightProvider,
          // Fade in tiles smoothly instead of popping in.
          tileDisplay: const TileDisplay.fadeIn(),
        ),

        // ── Route polyline ──────────────────────────────────
        if (navProvider.osmPolylines.isNotEmpty)
          PolylineLayer(polylines: navProvider.osmPolylines),

        // ── Location + destination markers ──────────────────
        if (navProvider.osmMarkers.isNotEmpty)
          MarkerLayer(markers: navProvider.osmMarkers),
      ],
    );
  }
}

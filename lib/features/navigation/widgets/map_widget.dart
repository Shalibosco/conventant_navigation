// lib/features/navigation/widgets/map_widget.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/app_constants.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentLocation;
  final void Function(String)? onLocationSelected;

  const MapWidget({
    super.key,
    required this.mapController,
    this.currentLocation,
    this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(  // Changed from 'center' to 'initialCenter'
          AppConstants.campusLatitude,
          AppConstants.campusLongitude,
        ),
        initialZoom: 16.0,  // Changed from 'zoom'
        maxZoom: 19.0,
        minZoom: 14.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Base map layer
        TileLayer(
          urlTemplate: AppConstants.mapTileUrl,
          userAgentPackageName: 'com.covenant.navigator',
        ),

        // Campus boundary - FIXED PolygonLayer
        PolygonLayer(
          polygons: [
            Polygon(
              points: AppConstants.campusBoundary
                  .map((coord) => LatLng(coord[0], coord[1]))
                  .toList(),
              color: Colors.blue.withOpacity(0.2),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
              // 'isFilled' parameter removed - polygons are always filled
            ),
          ],
        ),

        // Campus locations markers - FIXED MarkerLayer
        MarkerLayer(
          markers: [
            for (final entry in AppConstants.campusLocations.entries)
              Marker(
                point: LatLng(
                  entry.value['lat'] as double,
                  entry.value['lng'] as double,
                ),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    onLocationSelected?.call(entry.key);
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getLocationIcon(entry.key),
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value['name'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Current location marker
        if (currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation!,
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  IconData _getLocationIcon(String locationKey) {
    switch (locationKey) {
      case 'chapel':
        return Icons.church;
      case 'library':
        return Icons.library_books;
      case 'cafeteria':
        return Icons.restaurant;
      default:
        return Icons.location_on;
    }
  }
}
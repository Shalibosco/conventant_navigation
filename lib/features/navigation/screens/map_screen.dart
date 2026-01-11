import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/app_constants.dart';
import '../../../features/multilingual/language_provider.dart';
import '../widgets/map_widget.dart';
import '../../voice_assistant/voice_pro.dart';  // Changed from voice_ui.dart
import '../../information/info_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  String? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Covenant University Navigator',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (language) {
              final provider = Provider.of<LanguageProvider>(context, listen: false);
              provider.changeLanguage(language);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'yo',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Yoruba'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'ig',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Igbo'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const InformationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            mapController: _mapController,
            currentLocation: _currentLocation,
            onLocationSelected: (String location) {
              setState(() {
                _selectedLocation = location;
              });
            },
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),  // Reverted to withOpacity
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AppConstants.campusLocations.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value['name'] as String),
                      selected: _selectedLocation == entry.key,
                      onSelected: (selected) {
                        setState(() {
                          _selectedLocation = selected ? entry.key : null;
                          _mapController.move(
                            LatLng(
                              entry.value['lat'] as double,
                              entry.value['lng'] as double,
                            ),
                            18,
                          );
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location',
              onPressed: () {
                // Get current location
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Simple voice button instead of VoiceAssistantButton widget
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'voice',
              onPressed: () {
                final voiceProvider = Provider.of<VoiceProvider>(context, listen: false);
                voiceProvider.startListening();
              },
              child: const Icon(Icons.mic),
            ),
          ),
        ],
      ),
    );
  }
}
// lib/features/navigation/providers/navigation_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/location_model.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../../../data/repositories/location_repository.dart';
import '../../voice_assistant/providers/voice_provider.dart';

enum MapEngineType { google, osm }

class NavigationProvider extends ChangeNotifier {
  final LocationRepository _repository;
  final LocationService _locationService;
  final RouteService _routeService;

  NavigationProvider(this._repository, this._locationService, this._routeService);

  // 🛰️ State Variables
  LatLng? _userLocation;
  LocationModel? _selectedDestination;
  bool _isNavigating = false;
  String _activeFilter = 'all';
  MapEngineType _activeEngine = MapEngineType.osm;

  List<LocationModel> _allLocations = [];
  List<LocationModel> _filteredLocations = [];
  List<LatLng> _routePoints = [];
  
  // Voice direction control
  VoiceProvider? _voiceProvider;

  // 🧲 Getters
  LatLng? get userLocation => _userLocation;
  LocationModel? get selectedDestination => _selectedDestination;
  bool get isNavigating => _isNavigating;
  String get activeFilter => _activeFilter;
  List<LocationModel> get searchResults => _filteredLocations;
  bool get hasRoute => _routePoints.isNotEmpty;
  MapEngineType get activeEngine => _activeEngine;

  void updateVoiceProvider(VoiceProvider voice) {
    _voiceProvider = voice;
  }
  
  void setMapEngine(MapEngineType engine) {
    _activeEngine = engine;
    notifyListeners();
  }

  // 📍 Getter for OpenStreetMap UI Markers
  List<Marker> get osmMarkers {
    final List<Marker> markers = [];

    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.person_pin_circle_rounded, color: Colors.blue, size: 40),
        ),
      );
    }

    if (_selectedDestination != null) {
      markers.add(
        Marker(
          point: LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
          width: 45,
          height: 45,
          child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 45),
        ),
      );
    }

    return markers;
  }

  // 🛣️ Getter for OpenStreetMap UI Route Lines
  List<Polyline> get osmPolylines {
    if (_routePoints.isEmpty) return [];

    return [
      Polyline(
        points: _routePoints,
        color: const Color(0xFF800000), // ✅ Maroon Hex code for Covenant University
        strokeWidth: 5.0,
      ),
    ];
  }

  // 🏃‍♂️ Distance Calculation
  double get distanceToDestination {
    if (_userLocation == null || _selectedDestination == null) return 0.0;

    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      _userLocation!,
      LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
    );
  }

  String get estimatedTime {
    final meters = distanceToDestination;
    if (meters == 0) return '0 mins';
    final minutes = (meters / 80).ceil();
    return '$minutes mins';
  }

  // 🚀 Logic Methods
  Future<void> initialize() async {
    final (locations, _) = await _repository.getAllLocations();
    if (locations != null) {
      _allLocations = locations;
      _filteredLocations = locations;
    }
    notifyListeners();
  }

  Future<void> fetchUserLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _userLocation = position;
      notifyListeners();
    }
  }

  void startLocationTracking() {
    _locationService.trackLocation().listen((position) {
      final oldLocation = _userLocation;
      _userLocation = position;
      
      if (_isNavigating) {
        _updateRoute();
        _checkProximityAndSpeak(oldLocation, position);
      }
      notifyListeners();
    });
  }

  void _checkProximityAndSpeak(LatLng? oldPos, LatLng newPos) {
    if (_selectedDestination == null || _voiceProvider == null) return;
    
    final dist = distanceToDestination;
    
    // Arrival check
    if (dist < 15) {
      _voiceProvider!.speak("You have arrived at ${_selectedDestination!.name}.");
      cancelNavigation();
      return;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredLocations = _allLocations;
    } else {
      _filteredLocations = _allLocations.where((loc) {
        return loc.name.toLowerCase().contains(query.toLowerCase()) ||
            loc.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void filterByCategory(String category) {
    _activeFilter = category;
    if (category == 'all') {
      _filteredLocations = _allLocations;
    } else {
      _filteredLocations = _allLocations.where((loc) => loc.category == category).toList();
    }
    notifyListeners();
  }

  void navigateTo(LocationModel destination) {
    _selectedDestination = destination;
    _isNavigating = true;
    _updateRoute();
    
    if (_voiceProvider != null) {
       _voiceProvider!.speak("Navigating to ${destination.name}. Follow the route on the map.");
    }

    notifyListeners();
  }

  void cancelNavigation() {
    _isNavigating = false;
    _selectedDestination = null;
    _routePoints = [];
    notifyListeners();
  }

  Future<void> _updateRoute() async {
    if (_userLocation == null || _selectedDestination == null) return;

    final destLatLng = LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude);
    final points = await _routeService.getRoutePoints(_userLocation!, destLatLng);

    _routePoints = points;
    notifyListeners();
  }
}

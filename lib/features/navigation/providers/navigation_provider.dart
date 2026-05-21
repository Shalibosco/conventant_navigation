// lib/features/navigation/providers/navigation_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/location_model.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../services/map_trail_service.dart';
import '../../../data/repositories/location_repository.dart';
import '../../voice_assistant/providers/voice_provider.dart';

class NavigationProvider extends ChangeNotifier {
  final LocationRepository _repository;
  final LocationService _locationService;
  final RouteService _routeService;
  final MapTrailService _trailService = MapTrailService();

  NavigationProvider(this._repository, this._locationService, this._routeService);

  // 🛰️ State Variables
  LatLng? _userLocation;
  LocationModel? _selectedDestination;
  bool _isNavigating = false;
  String _activeFilter = 'all';
  String _searchQuery = '';

  List<LocationModel> _allLocations = [];
  List<LocationModel> _filteredLocations = [];
  List<LatLng> _routePoints = [];

  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _lastRouteFrom; // throttle: only recalculate route after >30m movement

  // Voice direction control
  VoiceProvider? _voiceProvider;

  // 🧲 Getters
  LatLng? get userLocation => _userLocation;
  LocationModel? get selectedDestination => _selectedDestination;
  bool get isNavigating => _isNavigating;
  String get activeFilter => _activeFilter;
  List<LocationModel> get searchResults => _filteredLocations;
  bool get hasRoute => _routePoints.isNotEmpty;
  MapTrailService get trailService => _trailService;

  void updateVoiceProvider(VoiceProvider voice) {
    _voiceProvider = voice;
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
    final List<Polyline> polylines = [];
    
    // Add user trail (breadcrumb trail) when navigating
    if (_isNavigating && _trailService.hasTrail && _trailService.trailPoints.length > 1) {
      polylines.add(
        Polyline(
          points: _trailService.trailPoints,
          color: const Color(0xFF4A90E2).withValues(alpha: 0.6), // Light blue trail
          strokeWidth: 3.0,
          // isDotted: false,
        ),
      );
    }
    
    // Add navigation route
    if (_routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _routePoints,
          color: const Color(0xFF800000), // ✅ Maroon Hex code for Covenant University
          strokeWidth: 5.0,
        ),
      );
    }
    
    return polylines;
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
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.trackLocation().listen(
      (position) {
        _userLocation = position;

        if (_isNavigating) {
          _trailService.addTrailPoint(position);
          _maybeUpdateRoute(position);
          _checkProximityAndSpeak(position);
        }
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('NavigationProvider: location stream error — $error');
      },
    );
  }

  void _maybeUpdateRoute(LatLng position) {
    if (_lastRouteFrom == null) {
      _updateRoute();
      return;
    }
    const distCalc = Distance();
    final moved = distCalc.as(LengthUnit.Meter, _lastRouteFrom!, position);
    if (moved > 30) _updateRoute();
  }

  void _checkProximityAndSpeak(LatLng newPos) {
    if (_selectedDestination == null || _voiceProvider == null) return;

    final dist = distanceToDestination;

    if (dist < 15) {
      _voiceProvider!.speak("You have arrived at ${_selectedDestination!.name}.");
      cancelNavigation();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _activeFilter = category;
    _applyFilters();
  }

  void _applyFilters() {
    var results = _allLocations;

    if (_activeFilter != 'all') {
      results = results.where((loc) => loc.category == _activeFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      results = results.where((loc) {
        return loc.name.toLowerCase().contains(q) ||
            loc.category.toLowerCase().contains(q);
      }).toList();
    }

    _filteredLocations = results;
    notifyListeners();
  }

   void navigateTo(LocationModel destination) {
     _selectedDestination = destination;
     _isNavigating = true;
     _lastRouteFrom = null;

     // Reset trail for new navigation
     if (_userLocation != null) {
       _trailService.resetTrail(_userLocation!);
     } else {
       _trailService.clearTrail();
     }

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
     _trailService.clearTrail(); // Clear trail when navigation ends
     notifyListeners();
   }

  Future<void> _updateRoute() async {
    if (_userLocation == null || _selectedDestination == null) return;

    _lastRouteFrom = _userLocation;
    final destLatLng = LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude);
    final points = await _routeService.getRoutePoints(_userLocation!, destLatLng);

    _routePoints = points;
    notifyListeners();
  }

  // 🛣️ Get trail distance in kilometers
  double get trailDistance => _trailService.getTotalTrailDistance();

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    _routeService.dispose();
    _trailService.dispose();
    super.dispose();
  }
}

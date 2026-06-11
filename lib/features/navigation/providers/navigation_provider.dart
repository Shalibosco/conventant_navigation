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

  NavigationProvider(
    this._repository,
    this._locationService,
    this._routeService,
  );

  // 🛰️ State Variables
  LatLng? _userLocation;
  LocationModel? _selectedDestination;
  bool _isNavigating = false;
  bool _isRerouting = false;
  bool _isUpdatingRoute = false;
  String _activeFilter = 'all';
  String _searchQuery = '';

  List<LocationModel> _allLocations = [];
  List<LocationModel> _filteredLocations = [];
  List<LatLng> _routePoints = [];

  StreamSubscription<LatLng>? _locationSubscription;
  LatLng?
  _lastRouteFrom; // throttle: only recalculate route after >30m movement
  DateTime? _lastRerouteTime;
  DateTime? _lastGuidanceTime;
  LatLng? _lastGuidancePoint;
  final Set<int> _spokenDistanceCues = <int>{};
  static const Duration _rerouteCooldown = Duration(seconds: 10);
  static const List<int> _distanceCueMeters = [20, 50, 100, 200, 300];
  static const Map<String, Map<String, String>> _directionLabels = {
    'en': {
      'north': 'north',
      'north-east': 'north-east',
      'east': 'east',
      'south-east': 'south-east',
      'south': 'south',
      'south-west': 'south-west',
      'west': 'west',
      'north-west': 'north-west',
    },
    'yo': {
      'north': 'ariwa',
      'north-east': 'ariwa-oorun',
      'east': 'oorun',
      'south-east': 'guusu-oorun',
      'south': 'guusu',
      'south-west': 'guusu-iwo-oorun',
      'west': 'iwo-oorun',
      'north-west': 'ariwa-iwo-oorun',
    },
    'ig': {
      'north': 'ugwu',
      'north-east': 'ugwu-ọwụwa anyanwụ',
      'east': 'ọwụwa anyanwụ',
      'south-east': 'ndịda-ọwụwa anyanwụ',
      'south': 'ndịda',
      'south-west': 'ndịda-ọdịda anyanwụ',
      'west': 'ọdịda anyanwụ',
      'north-west': 'ugwu-ọdịda anyanwụ',
    },
    'pidgin': {
      'north': 'north',
      'north-east': 'north-east',
      'east': 'east',
      'south-east': 'south-east',
      'south': 'south',
      'south-west': 'south-west',
      'west': 'west',
      'north-west': 'north-west',
    },
  };

  // Voice direction control
  VoiceProvider? _voiceProvider;

  // 🧲 Getters
  LatLng? get userLocation => _userLocation;
  LocationModel? get selectedDestination => _selectedDestination;
  bool get isNavigating => _isNavigating;
  bool get isRerouting => _isRerouting;
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
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }

    if (_selectedDestination != null) {
      markers.add(
        Marker(
          point: LatLng(
            _selectedDestination!.latitude,
            _selectedDestination!.longitude,
          ),
          width: 45,
          height: 45,
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.red,
            size: 45,
          ),
        ),
      );
    }

    return markers;
  }

  // 🛣️ Getter for OpenStreetMap UI Route Lines
  List<Polyline> get osmPolylines {
    final List<Polyline> polylines = [];

    // Add user trail (breadcrumb trail) when navigating
    if (_isNavigating &&
        _trailService.hasTrail &&
        _trailService.trailPoints.length > 1) {
      polylines.add(
        Polyline(
          points: _trailService.trailPoints,
          color: const Color(
            0xFF4A90E2,
          ).withValues(alpha: 0.6), // Light blue trail
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
          color: const Color(
            0xFF800000,
          ), // ✅ Maroon Hex code for Covenant University
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
    unawaited(_startLocationTracking());
  }

  Future<void> _startLocationTracking() async {
    await _locationSubscription?.cancel();
    await _locationService.startTracking();

    _locationSubscription = _locationService.locationStream.listen(
      (LatLng position) {
        final previousLocation = _userLocation;
        _userLocation = position;

        if (_isNavigating) {
          _trailService.addTrailPoint(position);
          final heading = _movementHeading(previousLocation, position);
          if (!_maybeReroute(position, heading)) {
            _maybeUpdateRoute(position);
          }
          _checkProximityAndSpeak();
          _maybeSpeakNavigationGuidance(position);
        }
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('NavigationProvider: location stream error — $error');
      },
    );
  }

  double? _movementHeading(LatLng? previousLocation, LatLng currentLocation) {
    if (previousLocation == null) return null;

    const distCalc = Distance();
    final moved = distCalc.as(
      LengthUnit.Meter,
      previousLocation,
      currentLocation,
    );
    if (moved < 2) return null;

    return distCalc.bearing(previousLocation, currentLocation);
  }

  bool _maybeReroute(LatLng position, double? heading) {
    if (_routePoints.length < 2 || _isUpdatingRoute) return false;

    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!) < _rerouteCooldown) {
      return false;
    }

    final shouldReroute = _routeService.shouldReroute(
      currentLocation: position,
      routePoints: _routePoints,
      heading: heading,
    );
    if (!shouldReroute) return false;

    _lastRerouteTime = now;
    _speakReroutingCue();
    unawaited(_updateRoute(isRerouting: true));
    return true;
  }

  void _maybeUpdateRoute(LatLng position) {
    if (_lastRouteFrom == null) {
      unawaited(_updateRoute());
      return;
    }
    const distCalc = Distance();
    final moved = distCalc.as(LengthUnit.Meter, _lastRouteFrom!, position);
    if (moved > 30) {
      unawaited(_updateRoute());
    }
  }

  void _speakReroutingCue() {
    if (_voiceProvider == null) return;
    if (_voiceProvider!.isListening ||
        _voiceProvider!.isProcessing ||
        _voiceProvider!.isSpeaking) {
      return;
    }
    _voiceProvider!.speak(_reroutingPhrase());
  }

  void _checkProximityAndSpeak() {
    if (_selectedDestination == null || _voiceProvider == null) return;

    final dist = distanceToDestination;

    if (dist < 15) {
      _voiceProvider!.speak(
        _arrivedPhrase(
          _selectedDestination!.getLocalizedName(_activeVoiceLang),
        ),
      );
      cancelNavigation();
    }
  }

  void _maybeSpeakNavigationGuidance(LatLng position) {
    if (_selectedDestination == null || _voiceProvider == null) return;
    if (_voiceProvider!.isListening || _voiceProvider!.isProcessing) return;

    final remaining = distanceToDestination.round();
    if (_trySpeakDistanceCue(remaining)) return;

    final now = DateTime.now();
    if (_lastGuidanceTime != null &&
        now.difference(_lastGuidanceTime!).inSeconds < 18) {
      return;
    }

    if (_lastGuidancePoint != null) {
      const distCalc = Distance();
      final moved = distCalc.as(
        LengthUnit.Meter,
        _lastGuidancePoint!,
        position,
      );
      if (moved < 12) return;
    }

    final directionKey = _directionTowardNextPoint(position);
    if (directionKey == null) return;
    final direction = _directionLabel(directionKey);

    _voiceProvider!.speak(_continuePhrase(direction));
    _lastGuidanceTime = now;
    _lastGuidancePoint = position;
  }

  bool _trySpeakDistanceCue(int remainingMeters) {
    if (_voiceProvider == null) return false;

    int? cue;
    for (final mark in _distanceCueMeters) {
      if (remainingMeters <= mark) {
        cue = mark;
        break;
      }
    }
    if (cue == null) return false;
    if (_spokenDistanceCues.contains(cue)) return false;

    _spokenDistanceCues.add(cue);
    _voiceProvider!.speak(_distancePhrase(cue));
    _lastGuidanceTime = DateTime.now();
    _lastGuidancePoint = _userLocation;
    return true;
  }

  String? _directionTowardNextPoint(LatLng from) {
    if (_routePoints.length < 2) return null;

    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    const distCalc = Distance();

    for (var i = 0; i < _routePoints.length; i++) {
      final d = distCalc.as(LengthUnit.Meter, from, _routePoints[i]);
      if (d < nearestDistance) {
        nearestDistance = d;
        nearestIndex = i;
      }
    }

    final targetIndex = (nearestIndex + 3).clamp(0, _routePoints.length - 1);
    final target = _routePoints[targetIndex];
    final bearing = distCalc.bearing(from, target);
    return _bearingToDirectionKey(bearing);
  }

  String _bearingToDirectionKey(double bearing) {
    final normalized = (bearing % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'north';
    if (normalized < 67.5) return 'north-east';
    if (normalized < 112.5) return 'east';
    if (normalized < 157.5) return 'south-east';
    if (normalized < 202.5) return 'south';
    if (normalized < 247.5) return 'south-west';
    if (normalized < 292.5) return 'west';
    return 'north-west';
  }

  String _directionLabel(String directionKey) {
    final lang = _activeVoiceLang;
    return _directionLabels[lang]?[directionKey] ??
        _directionLabels['en']![directionKey] ??
        directionKey;
  }

  String get _activeVoiceLang =>
      _voiceProvider?.currentLanguageCode == 'yo' ||
          _voiceProvider?.currentLanguageCode == 'ig' ||
          _voiceProvider?.currentLanguageCode == 'pidgin'
      ? _voiceProvider!.currentLanguageCode
      : 'en';

  String _navigatingPhrase(String placeName) {
    switch (_activeVoiceLang) {
      case 'yo':
        return 'A ń lọ sí $placeName. Tẹ̀lé ipa-ọ̀nà lórí maapu.';
      case 'ig':
        return 'A na-aga $placeName. Soro ụzọ ahụ n\'ime maapụ.';
      case 'pidgin':
        return 'I dey navigate go $placeName. Follow route for map.';
      default:
        return 'Navigating to $placeName. Follow the route on the map.';
    }
  }

  String _arrivedPhrase(String placeName) {
    switch (_activeVoiceLang) {
      case 'yo':
        return 'O ti dé $placeName.';
      case 'ig':
        return 'I eruola $placeName.';
      case 'pidgin':
        return 'You don reach $placeName.';
      default:
        return 'You have arrived at $placeName.';
    }
  }

  String _continuePhrase(String direction) {
    switch (_activeVoiceLang) {
      case 'yo':
        return 'Tẹ̀síwájú sí $direction.';
      case 'ig':
        return 'Gaa n\'ihu n\'akụkụ $direction.';
      case 'pidgin':
        return 'Continue dey go $direction.';
      default:
        return 'Continue $direction.';
    }
  }

  String _reroutingPhrase() {
    switch (_activeVoiceLang) {
      case 'yo':
        return 'Mo ń tún ipa-ọ̀nà ṣe.';
      case 'ig':
        return 'Ana m agbakọ ụzọ ọhụrụ.';
      case 'pidgin':
        return 'I dey find new route.';
      default:
        return 'Rerouting. Follow the updated route on the map.';
    }
  }

  String _distancePhrase(int meters) {
    switch (_activeVoiceLang) {
      case 'yo':
        return 'O kù bíi mita $meters.';
      case 'ig':
        return 'Ị fọdụrụ ihe dị ka mita $meters.';
      case 'pidgin':
        return 'You remain like $meters meters.';
      default:
        return 'You are about $meters meters away.';
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
        final fields = <String>[
          loc.name,
          loc.category,
          loc.description,
          ...?loc.localizedNames?.values,
          ...?loc.localizedDescriptions?.values,
          ...?loc.tags,
        ];
        return fields.any((field) => field.toLowerCase().contains(q));
      }).toList();
    }

    _filteredLocations = results;
    notifyListeners();
  }

  void navigateTo(LocationModel destination, {bool announce = true}) {
    _selectedDestination = destination;
    _isNavigating = true;
    _isRerouting = false;
    _lastRouteFrom = null;
    _lastRerouteTime = null;
    _lastGuidanceTime = null;
    _lastGuidancePoint = null;
    _spokenDistanceCues.clear();

    // Reset trail for new navigation
    if (_userLocation != null) {
      _trailService.resetTrail(_userLocation!);
    } else {
      _trailService.clearTrail();
    }

    unawaited(_prepareNavigationRoute());

    if (announce && _voiceProvider != null) {
      _voiceProvider!.speak(
        _navigatingPhrase(destination.getLocalizedName(_activeVoiceLang)),
      );
    }

    notifyListeners();
  }

  void cancelNavigation() {
    _isNavigating = false;
    _isRerouting = false;
    _selectedDestination = null;
    _lastRouteFrom = null;
    _lastRerouteTime = null;
    _lastGuidanceTime = null;
    _lastGuidancePoint = null;
    _spokenDistanceCues.clear();
    _routePoints = [];
    _trailService.clearTrail(); // Clear trail when navigation ends
    notifyListeners();
  }

  Future<void> _prepareNavigationRoute() async {
    if (_userLocation == null) {
      await fetchUserLocation();
    }
    if (_userLocation != null && _selectedDestination != null) {
      await _updateRoute();
    }
  }

  Future<void> _updateRoute({bool isRerouting = false}) async {
    if (_userLocation == null || _selectedDestination == null) return;
    if (_isUpdatingRoute) return;

    _isUpdatingRoute = true;
    if (isRerouting) {
      _isRerouting = true;
      notifyListeners();
    }

    final routeStart = _userLocation!;
    final destLatLng = LatLng(
      _selectedDestination!.latitude,
      _selectedDestination!.longitude,
    );

    try {
      final route = await _routeService.getRoute(routeStart, destLatLng);
      _lastRouteFrom = routeStart;
      _routePoints = route.points;
    } finally {
      _isUpdatingRoute = false;
      if (isRerouting) {
        _isRerouting = false;
      }
      notifyListeners();
    }
  }

  // 🛣️ Get trail distance in kilometers
  double get trailDistance => _trailService.totalDistanceKm;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    _routeService.dispose();
    _trailService.dispose();
    super.dispose();
  }
}

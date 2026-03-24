// lib/features/navigation/providers/navigation_provider.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../../../data/models/location_model.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/constants/app_constants.dart';

enum NavigationState { idle, loading, navigating, searching, error }

class NavigationProvider extends ChangeNotifier {
  final LocationService _locationService = sl<LocationService>();
  final RouteService _routeService = sl<RouteService>();
  final LocationRepository _locationRepo = sl<LocationRepository>();

  NavigationState _state = NavigationState.idle;
  LatLng? _userLocation;
  LocationModel? _selectedDestination;
  List<LatLng> _routePoints = [];
  List<LocationModel> _allLocations = [];
  List<LocationModel> _filteredLocations = [];
  List<LocationModel> _searchResults = [];
  String? _errorMessage;
  String _activeFilter = 'all';
  bool _isTrackingLocation = false;
  double _distanceToDestination = 0;
  String _estimatedTime = '';

  // ── Getters ───────────────────────────────────────────────
  NavigationState get state => _state;
  LatLng? get userLocation => _userLocation;
  LocationModel? get selectedDestination => _selectedDestination;
  List<LatLng> get routePoints => _routePoints;
  List<LocationModel> get allLocations => _allLocations;
  List<LocationModel> get filteredLocations => _filteredLocations;
  List<LocationModel> get searchResults => _searchResults;
  String? get errorMessage => _errorMessage;
  String get activeFilter => _activeFilter;
  bool get isNavigating => _state == NavigationState.navigating;
  bool get hasRoute => _routePoints.isNotEmpty;
  double get distanceToDestination => _distanceToDestination;
  String get estimatedTime => _estimatedTime;

  // ── Initialize ────────────────────────────────────────────
  Future<void> initialize() async {
    _setState(NavigationState.loading);
    await Future.wait([
      loadLocations(),
      fetchUserLocation(),
    ]);
    _setState(NavigationState.idle);
  }

  // ── Load all campus locations ─────────────────────────────
  Future<void> loadLocations() async {
    final (locations, failure) = await _locationRepo.getAllLocations();
    if (failure != null) {
      _setError(failure.message);
      return;
    }
    _allLocations = locations ?? [];
    _filteredLocations = _allLocations;
    notifyListeners();
  }

  // ── Fetch user GPS position ───────────────────────────────
  Future<void> fetchUserLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      _userLocation = location;
      notifyListeners();
    } catch (e) {
      // Non-fatal — map still works without user location
      debugPrint('Location fetch error: $e');
    }
  }

  // ── Start live GPS tracking ───────────────────────────────
  void startLocationTracking() {
    if (_isTrackingLocation) return;
    _isTrackingLocation = true;
    _locationService.trackLocation().listen((location) {
      _userLocation = location;
      if (_selectedDestination != null) _updateDistanceInfo();
      notifyListeners();
    });
  }

  // ── Navigate to a destination ─────────────────────────────
  Future<void> navigateTo(LocationModel destination,
      {bool isOnline = true}) async {
    _selectedDestination = destination;
    _setState(NavigationState.navigating);
    _routePoints = [];

    final from = _userLocation ?? Helpers.campusCenter;
    final to = LatLng(destination.latitude, destination.longitude);

    try {
      if (isOnline) {
        _routePoints = await _routeService.getWalkingRoute(from, to);
      } else {
        _routePoints = _routeService.getStraightLineRoute(from, to);
      }
    } catch (_) {
      // Fallback to straight line if OSRM fails
      _routePoints = _routeService.getStraightLineRoute(from, to);
    }

    _updateDistanceInfo();
    notifyListeners();
  }

  void _updateDistanceInfo() {
    if (_userLocation == null || _selectedDestination == null) return;
    _distanceToDestination = Helpers.calculateDistance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      _selectedDestination!.latitude,
      _selectedDestination!.longitude,
    );
    _estimatedTime = Helpers.estimateWalkTime(_distanceToDestination);
  }

  // ── Cancel active navigation ──────────────────────────────
  void cancelNavigation() {
    _selectedDestination = null;
    _routePoints = [];
    _distanceToDestination = 0;
    _estimatedTime = '';
    _setState(NavigationState.idle);
  }

  // ── Filter markers by category ────────────────────────────
  void filterByCategory(String category) {
    _activeFilter = category;
    if (category == 'all') {
      _filteredLocations = _allLocations;
    } else {
      _filteredLocations =
          _allLocations.where((l) => l.category == category).toList();
    }
    notifyListeners();
  }

  // ── Text search ───────────────────────────────────────────
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _setState(NavigationState.searching);
    final (results, _) = await _locationRepo.searchLocations(query);
    _searchResults = results ?? [];
    _setState(NavigationState.idle);
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // ── Navigate by location ID (used by voice commands) ──────
  Future<void> navigateToLocationById(String id,
      {bool isOnline = true}) async {
    final (location, failure) = await _locationRepo.getLocationById(id);
    if (failure != null || location == null) return;
    await navigateTo(location, isOnline: isOnline);
  }

  void _setState(NavigationState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = NavigationState.error;
    notifyListeners();
  }
}
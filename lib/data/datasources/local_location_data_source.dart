// lib/data/datasources/local_location_data_source.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/location_model.dart';
import '../../../core/error/exceptions.dart'; // ✅ Make sure this defines StorageException

abstract class LocalLocationDataSource {
  Future<List<LocationModel>> getLocations();
  Future<LocationModel?> getLocationById(String id);
  Future<List<LocationModel>> searchLocations(String query);
  Future<List<LocationModel>> getLocationsByCategory(String category);
  Future<void> cacheLocations(List<LocationModel> locations);
  Future<void> clearCache();
}

class LocalLocationDataSourceImpl implements LocalLocationDataSource {
  final Box<LocationModel> _locationBox;
  static const String _assetPath = 'assets/map/covenant_locations.json';

  LocalLocationDataSourceImpl(this._locationBox);

  @override
  Future<List<LocationModel>> getLocations() async {
    try {
      if (_locationBox.isNotEmpty) {
        return _locationBox.values.toList();
      }

      // Fallback to asset bundle if Hive is empty
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      final List<LocationModel> locations = jsonList
          .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      await cacheLocations(locations);
      return locations;
    } catch (e) {
      throw StorageException('Failed to load locations: $e');
    }
  }

  @override
  Future<LocationModel?> getLocationById(String id) async {
    try {
      final locations = await getLocations();
      return locations.firstWhere(
            (loc) => loc.id == id,
        orElse: () => throw StorageException('Location not found'),
      );
    } catch (e) {
      throw StorageException('Error finding location by ID: $e');
    }
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      if (query.trim().isEmpty) return <LocationModel>[];

      final locations = await getLocations();
      final searchLower = query.toLowerCase().trim();

      return locations.where((loc) {
        return loc.name.toLowerCase().contains(searchLower) ||
            loc.category.toLowerCase().contains(searchLower) ||
            loc.description.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      throw StorageException('Error searching locations: $e');
    }
  }

  @override
  Future<List<LocationModel>> getLocationsByCategory(String category) async {
    try {
      final locations = await getLocations();
      return locations.where((loc) => loc.category == category).toList();
    } catch (e) {
      throw StorageException('Error filtering by category: $e');
    }
  }

  @override
  Future<void> cacheLocations(List<LocationModel> locations) async {
    try {
      final Map<String, LocationModel> locationMap = {
        for (var loc in locations) loc.id: loc
      };
      await _locationBox.putAll(locationMap);
    } catch (e) {
      throw StorageException('Failed to cache locations to Hive: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _locationBox.clear();
    } catch (e) {
      throw StorageException('Failed to clear location cache: $e');
    }
  }
}
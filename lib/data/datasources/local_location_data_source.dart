// lib/data/datasources/local_location_data_source.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/location_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';

class LocalLocationDataSource {
  // Version bump forces re-seed when location data changes
  static const int _dataVersion = 2;
  static const String _versionKey = 'locations_data_version';

  Future<List<LocationModel>> getLocations() async {
    try {
      final box = await Hive.openBox<LocationModel>(AppConstants.locationsBox);
      final versionBox = await Hive.openBox(_versionKey);
      final storedVersion = versionBox.get('version', defaultValue: 0) as int;

      // Re-seed if version changed or box is empty
      if (box.isEmpty || storedVersion < _dataVersion) {
        await box.clear();
        await _seedFromJson(box);
        await versionBox.put('version', _dataVersion);
      }

      return box.values.toList();
    } catch (e) {
      throw StorageException('Failed to load locations: $e');
    }
  }

  Future<void> _seedFromJson(Box<LocationModel> box) async {
    final jsonString =
    await rootBundle.loadString(AppConstants.locationsJsonPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final locations = jsonList
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final loc in locations) {
      await box.put(loc.id, loc);
    }
  }

  Future<LocationModel?> getLocationById(String id) async {
    try {
      final box = await Hive.openBox<LocationModel>(AppConstants.locationsBox);
      return box.get(id);
    } catch (e) {
      throw StorageException('Failed to get location: $e');
    }
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    final all = await getLocations();
    final q = query.toLowerCase().trim();
    return all.where((loc) {
      return loc.name.toLowerCase().contains(q) ||
          loc.description.toLowerCase().contains(q) ||
          (loc.tags?.any((t) => t.toLowerCase().contains(q)) ?? false);
    }).toList();
  }

  Future<List<LocationModel>> getLocationsByCategory(String category) async {
    final all = await getLocations();
    return all.where((loc) => loc.category == category).toList();
  }

  Future<void> clearCache() async {
    final box = await Hive.openBox<LocationModel>(AppConstants.locationsBox);
    await box.clear();
  }
}
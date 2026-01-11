// lib/data/repositories/location_repository.dart
import 'package:hive_flutter/hive_flutter.dart';  // Changed import
import '../models/location_model.dart';

class LocationRepository {
  static const String _boxName = 'locations';
  late Box<LocationModel> _locationsBox;

  Future<void> init() async {
    // Make sure Hive is initialized first
    if (!Hive.isAdapterRegistered(LocationModelAdapter().typeId)) {
      Hive.registerAdapter(LocationModelAdapter());
    }
    _locationsBox = await Hive.openBox<LocationModel>(_boxName);
  }

  Future<void> addLocation(LocationModel location) async {
    await _locationsBox.put(location.id, location);
  }

  Future<LocationModel?> getLocation(String id) async {
    return _locationsBox.get(id);
  }

  Future<List<LocationModel>> getAllLocations() async {
    return _locationsBox.values.toList();
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    final allLocations = await getAllLocations();
    return allLocations.where((location) {
      return location.name.toLowerCase().contains(query.toLowerCase()) ||
          (location.tags?.any((tag) => tag.toLowerCase().contains(query.toLowerCase())) ?? false);
    }).toList();
  }

  Future<void> deleteLocation(String id) async {
    await _locationsBox.delete(id);
  }

  Future<void> clearAll() async {
    await _locationsBox.clear();
  }
}
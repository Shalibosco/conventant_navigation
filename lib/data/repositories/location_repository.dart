// lib/data/repositories/location_repository.dart

import '../datasources/local_location_data_source.dart';
import '../models/location_model.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';

class LocationRepository {
  final LocalLocationDataSource _dataSource;

  LocationRepository(this._dataSource);

  Future<(List<LocationModel>?, Failure?)> getAllLocations() async {
    try {
      final locations = await _dataSource.getLocations();
      return (locations, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  Future<(LocationModel?, Failure?)> getLocationById(String id) async {
    try {
      final location = await _dataSource.getLocationById(id);
      if (location == null) {
        return (null, const StorageFailure('Location not found'));
      }
      return (location, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  Future<(List<LocationModel>?, Failure?)> searchLocations(String query) async {
    try {
      final locations = await _dataSource.searchLocations(query);
      return (locations, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  Future<(List<LocationModel>?, Failure?)> getByCategory(
      String category) async {
    try {
      final locations = await _dataSource.getLocationsByCategory(category);
      return (locations, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
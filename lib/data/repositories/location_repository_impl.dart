// lib/data/repositories/location_repository_impl.dart

import '../datasources/local_location_data_source.dart';
import '../models/location_model.dart';
import 'location_repository.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocalLocationDataSource localDataSource;

  LocationRepositoryImpl(this.localDataSource);

  @override
  Future<(List<LocationModel>?, Failure?)> getAllLocations() async {
    try {
      final locations = await localDataSource.getLocations();
      return (locations, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(LocationModel?, Failure?)> getLocationById(String id) async {
    try {
      final location = await localDataSource.getLocationById(id);
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

  @override
  Future<(List<LocationModel>?, Failure?)> searchLocations(String query) async {
    try {
      final locations = await localDataSource.searchLocations(query);
      return (locations, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<LocationModel>?, Failure?)> getByCategory(String category) async {
    try {
      final locations = await localDataSource.getLocationsByCategory(category);
      return (locations, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
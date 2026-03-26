// lib/data/repositories/info_repository_impl.dart

import '../datasources/local_info_data_source.dart';
import '../models/info_model.dart';
import 'info_repository.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';

class InfoRepositoryImpl implements InfoRepository {
  final LocalInfoDataSource _dataSource;

  InfoRepositoryImpl(this._dataSource);

  @override
  Future<(List<InfoModel>?, Failure?)> getAllInfo() async {
    try {
      final items = await _dataSource.getInfoItems();
      return (items, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<InfoModel>?, Failure?)> getInfoByCategory(String category) async {
    try {
      final items = await _dataSource.getInfoByCategory(category);
      return (items, null);
    } on StorageException catch (e) {
      return (null, StorageFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
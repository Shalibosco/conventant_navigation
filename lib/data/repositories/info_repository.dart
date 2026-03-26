// lib/data/repositories/info_repository.dart

import '../models/info_model.dart';
import '../../core/error/failures.dart';

abstract class InfoRepository {
  Future<(List<InfoModel>?, Failure?)> getAllInfo();
  Future<(List<InfoModel>?, Failure?)> getInfoByCategory(String category);
}
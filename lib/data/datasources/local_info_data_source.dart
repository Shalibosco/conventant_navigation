// lib/data/datasources/local_info_data_source.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/info_model.dart';
import '../../core/error/exceptions.dart';

class LocalInfoDataSource {
  static const String _infoJsonPath = 'assets/map/campus_info.json';

  List<InfoModel>? _cachedInfo;

  Future<List<InfoModel>> getInfoItems() async {
    try {
      if (_cachedInfo != null) return _cachedInfo!;

      final jsonString = await rootBundle.loadString(_infoJsonPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      _cachedInfo = jsonList
          .map((e) => InfoModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return _cachedInfo!;
    } catch (e) {
      throw StorageException('Failed to load info items: $e');
    }
  }

  Future<List<InfoModel>> getInfoByCategory(String category) async {
    final all = await getInfoItems();
    return all.where((item) => item.category == category).toList();
  }
}
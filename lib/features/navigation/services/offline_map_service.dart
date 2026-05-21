// lib/features/navigation/services/offline_map_service.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';

class OfflineMapService {
  static Directory? _cacheDir;

  Future<Directory> getTileCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final tileDir = Directory('${appDir.path}/map_tiles');
    if (!tileDir.existsSync()) {
      tileDir.createSync(recursive: true);
    }
    _cacheDir = tileDir;
    return tileDir;
  }

  Future<int> getCacheSizeInMB() async {
    try {
      final dir = await getTileCacheDirectory();
      int totalBytes = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return (totalBytes / (1024 * 1024)).round();
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearTileCache() async {
    try {
      final dir = await getTileCacheDirectory();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        _cacheDir = null;
      }
    } catch (_) {}
  }

  /// Pre-caches OSM tiles for the campus bounding box at zoom levels 14–18.
  Future<void> preCacheCampusTiles({
    void Function(double progress)? onProgress,
  }) async {
    final tiles = _getTileCoordinates(
      north: AppConstants.campusBoundNorth,
      south: AppConstants.campusBoundSouth,
      east: AppConstants.campusBoundEast,
      west: AppConstants.campusBoundWest,
      minZoom: 14,
      maxZoom: 18,
    );

    int completed = 0;
    for (final tile in tiles) {
      await _downloadTile(tile[0], tile[1], tile[2]);
      completed++;
      onProgress?.call(completed / tiles.length);
    }
  }

  List<List<int>> _getTileCoordinates({
    required double north,
    required double south,
    required double east,
    required double west,
    required int minZoom,
    required int maxZoom,
  }) {
    final tiles = <List<int>>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final xMin = _lonToTile(west, z);
      final xMax = _lonToTile(east, z);
      final yMin = _latToTile(north, z);
      final yMax = _latToTile(south, z);
      for (int x = xMin; x <= xMax; x++) {
        for (int y = yMin; y <= yMax; y++) {
          tiles.add([z, x, y]);
        }
      }
    }
    return tiles;
  }

  int _lonToTile(double lon, int zoom) {
    return ((lon + 180) / 360 * (1 << zoom)).floor();
  }

  int _latToTile(double lat, int zoom) {
    final latRad = lat * math.pi / 180;
    return ((1 -
                math.log(math.tan(latRad) + 1 / math.cos(latRad)) /
                    math.pi) /
            2 *
            (1 << zoom))
        .floor();
  }

  Future<void> _downloadTile(int z, int x, int y) async {
    try {
      final dir = await getTileCacheDirectory();
      final file = File('${dir.path}/$z/$x/$y.png');
      if (file.existsSync()) return;
      file.parent.createSync(recursive: true);

      final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'CUNavigate/1.0 (Covenant University campus navigation)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {}
  }
}

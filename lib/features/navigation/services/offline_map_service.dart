// lib/features/navigation/services/offline_map_service.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';

class OfflineMapService {
  static Directory? _cacheDir;
  static const String _lightStyle = 'light';
  static const String _darkStyle = 'dark';

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

  String? get cacheDirectoryPath => _cacheDir?.path;

  File? getTileFileSync({
    required String style,
    required int z,
    required int x,
    required int y,
  }) {
    if (_cacheDir == null) return null;
    return File('${_cacheDir!.path}/${_sanitizeStyle(style)}/$z/$x/$y.png');
  }

  Future<void> cacheTileIfMissing({
    required String style,
    required int z,
    required int x,
    required int y,
  }) async {
    await _downloadTile(style: style, z: z, x: x, y: y);
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

  /// Pre-caches OSM tiles for the campus bounding box at the configured
  /// map zoom range.
  Future<void> preCacheCampusTiles({
    void Function(double progress)? onProgress,
    bool includeDarkTiles = true,
  }) async {
    final tiles = _getTileCoordinates(
      north: AppConstants.campusBoundNorth,
      south: AppConstants.campusBoundSouth,
      east: AppConstants.campusBoundEast,
      west: AppConstants.campusBoundWest,
      minZoom: AppConstants.minZoom.floor(),
      maxZoom: AppConstants.maxZoom.floor(),
    );

    int completed = 0;
    final total = tiles.length * (includeDarkTiles ? 2 : 1);

    for (final tile in tiles) {
      await _downloadTile(
        style: _lightStyle,
        z: tile[0],
        x: tile[1],
        y: tile[2],
      );
      completed++;
      onProgress?.call(completed / total);
    }

    if (includeDarkTiles) {
      for (final tile in tiles) {
        await _downloadTile(
          style: _darkStyle,
          z: tile[0],
          x: tile[1],
          y: tile[2],
        );
        completed++;
        onProgress?.call(completed / total);
      }
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
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            (1 << zoom))
        .floor();
  }

  String _sanitizeStyle(String style) {
    if (style == _darkStyle) return _darkStyle;
    return _lightStyle;
  }

  String _getTileUrl({
    required String style,
    required int z,
    required int x,
    required int y,
  }) {
    final mapStyle = _sanitizeStyle(style);
    if (mapStyle == _darkStyle) {
      const subdomains = ['a', 'b', 'c', 'd'];
      final subdomain = subdomains[(x + y) % subdomains.length];
      return 'https://$subdomain.basemaps.cartocdn.com/dark_all/$z/$x/$y.png';
    }
    return 'https://tile.openstreetmap.org/$z/$x/$y.png';
  }

  Future<void> _downloadTile({
    required String style,
    required int z,
    required int x,
    required int y,
  }) async {
    try {
      final dir = await getTileCacheDirectory();
      final file = File('${dir.path}/${_sanitizeStyle(style)}/$z/$x/$y.png');
      if (file.existsSync()) return;
      file.parent.createSync(recursive: true);

      final url = _getTileUrl(style: style, z: z, x: x, y: y);
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'CUNavigate/1.0 (Covenant University campus navigation)',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {}
  }
}

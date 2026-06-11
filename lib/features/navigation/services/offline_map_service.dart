// lib/features/navigation/services/offline_map_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';

// ── Tile style constants ──────────────────────────────────────────────────────

const String _lightStyle = 'light';
const String _darkStyle = 'dark';

/// OSM subdomains for load distribution during bulk downloads.
const List<String> _osmSubdomains = ['a', 'b', 'c'];

/// CartoCDN subdomains for dark tiles.
const List<String> _cartoSubdomains = ['a', 'b', 'c', 'd'];

/// Maximum concurrent tile downloads.
const int _maxConcurrency = 6;

/// Per-request timeout.
const Duration _requestTimeout = Duration(seconds: 10);

// ── Result types ──────────────────────────────────────────────────────────────

class PreCacheResult {
  final int downloaded;
  final int skipped;
  final int failed;
  final int total;

  const PreCacheResult({
    required this.downloaded,
    required this.skipped,
    required this.failed,
    required this.total,
  });

  double get progressFraction =>
      total == 0 ? 1.0 : (downloaded + skipped) / total;

  @override
  String toString() =>
      'PreCacheResult(downloaded: $downloaded, skipped: $skipped, '
      'failed: $failed, total: $total)';
}

// ── Service ───────────────────────────────────────────────────────────────────

class OfflineMapService {
  // ── HTTP client — reused across all requests ──────────────
  final http.Client _httpClient;

  /// Cancellation token. Set to true to abort an in-progress pre-cache.
  bool _cancelRequested = false;

  OfflineMapService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  // ── Cache directory ───────────────────────────────────────
  Directory? _cacheDir;

  Future<Directory> getTileCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final tileDir = Directory('${appDir.path}/map_tiles');
    if (!await tileDir.exists()) {
      await tileDir.create(recursive: true);
    }
    _cacheDir = tileDir;
    return tileDir;
  }

  String? get cacheDirectoryPath => _cacheDir?.path;

  // ── Tile file access ──────────────────────────────────────

  File? getTileFileSync({
    required String style,
    required int z,
    required int x,
    required int y,
  }) {
    if (_cacheDir == null) return null;
    return File('${_cacheDir!.path}/${_sanitizeStyle(style)}/$z/$x/$y.png');
  }

  /// Returns true if the tile is already cached on disk.
  bool isTileCached({
    required String style,
    required int z,
    required int x,
    required int y,
  }) {
    final file = getTileFileSync(style: style, z: z, x: x, y: y);
    return file?.existsSync() ?? false;
  }

  // ── Cache size ────────────────────────────────────────────

  /// Returns the total cache size in MB.
  ///
  /// Uses synchronous stat to avoid sequential async I/O per file.
  Future<double> getCacheSizeInMB() async {
    try {
      final dir = await getTileCacheDirectory();
      int totalBytes = 0;
      // listSync is faster than await-for for large flat directories.
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          totalBytes += entity.statSync().size;
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (e) {
      debugPrint('OfflineMapService: getCacheSizeInMB failed — $e');
      return 0;
    }
  }

  // ── Cache clear ───────────────────────────────────────────

  /// Deletes all cached tiles. Throws [FileSystemException] on failure.
  Future<void> clearTileCache() async {
    final dir = await getTileCacheDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _cacheDir = null;
  }

  // ── Tile count estimate ───────────────────────────────────

  /// Returns the number of tiles that would be downloaded for the campus
  /// bounding box between [minZoom] and [maxZoom].
  ///
  /// Call this before [preCacheCampusTiles] to show the user what they're
  /// committing to.
  int estimateTileCount({
    int minZoom = 14,
    int maxZoom = 18,
    bool includeDarkTiles = true,
  }) {
    final tiles = _getTileCoordinates(
      north: AppConstants.campusBoundNorth,
      south: AppConstants.campusBoundSouth,
      east: AppConstants.campusBoundEast,
      west: AppConstants.campusBoundWest,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    return tiles.length * (includeDarkTiles ? 2 : 1);
  }

  // ── Pre-cache ─────────────────────────────────────────────

  /// Pre-caches OSM tiles for the campus bounding box.
  ///
  /// Downloads up to [_maxConcurrency] tiles in parallel.
  /// Call [cancelPreCache] to abort mid-run.
  ///
  /// Returns a [PreCacheResult] summarizing what was downloaded, skipped,
  /// and failed — so the caller can surface meaningful feedback.
  Future<PreCacheResult> preCacheCampusTiles({
    int minZoom = 14,
    int maxZoom = 18,
    bool includeDarkTiles = true,
    void Function(double progress)? onProgress,
  }) async {
    _cancelRequested = false;

    final tiles = _getTileCoordinates(
      north: AppConstants.campusBoundNorth,
      south: AppConstants.campusBoundSouth,
      east: AppConstants.campusBoundEast,
      west: AppConstants.campusBoundWest,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );

    // Build the full work list: light tiles, then dark tiles if requested.
    final workItems = <({String style, int z, int x, int y})>[
      for (final t in tiles) (style: _lightStyle, z: t[0], x: t[1], y: t[2]),
      if (includeDarkTiles)
        for (final t in tiles) (style: _darkStyle, z: t[0], x: t[1], y: t[2]),
    ];

    final total = workItems.length;
    int downloaded = 0;
    int skipped = 0;
    int failed = 0;
    int processed = 0;

    // Process in parallel batches of [_maxConcurrency].
    for (int i = 0; i < workItems.length; i += _maxConcurrency) {
      if (_cancelRequested) break;

      final batch = workItems.skip(i).take(_maxConcurrency);
      final results = await Future.wait(
        batch.map(
          (item) =>
              _downloadTile(style: item.style, z: item.z, x: item.x, y: item.y),
        ),
      );

      for (final result in results) {
        switch (result) {
          case _TileResult.downloaded:
            downloaded++;
          case _TileResult.skipped:
            skipped++;
          case _TileResult.failed:
            failed++;
        }
        processed++;
        onProgress?.call(processed / total);
      }
    }

    return PreCacheResult(
      downloaded: downloaded,
      skipped: skipped,
      failed: failed,
      total: total,
    );
  }

  /// Aborts an in-progress [preCacheCampusTiles] call after the current
  /// batch completes.
  void cancelPreCache() => _cancelRequested = true;

  // ── Tile coordinate math ──────────────────────────────────

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

  int _lonToTile(double lon, int zoom) =>
      ((lon + 180) / 360 * (1 << zoom)).floor();

  int _latToTile(double lat, int zoom) {
    final latRad = lat * math.pi / 180;
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            (1 << zoom))
        .floor();
  }

  // ── URL + style ───────────────────────────────────────────

  String _sanitizeStyle(String style) =>
      style == _darkStyle ? _darkStyle : _lightStyle;

  String _getTileUrl({
    required String style,
    required int z,
    required int x,
    required int y,
  }) {
    if (_sanitizeStyle(style) == _darkStyle) {
      final sub = _cartoSubdomains[(x + y) % _cartoSubdomains.length];
      return 'https://$sub.basemaps.cartocdn.com/dark_all/$z/$x/$y.png';
    }
    // Distribute OSM requests across subdomains to avoid rate limiting.
    final sub = _osmSubdomains[(x + y) % _osmSubdomains.length];
    return 'https://$sub.tile.openstreetmap.org/$z/$x/$y.png';
  }

  // ── Download ──────────────────────────────────────────────

  Future<void> downloadTile({
    required String style,
    required int z,
    required int x,
    required int y,
  }) async {
    await _downloadTile(style: style, z: z, x: x, y: y);
  }

  Future<_TileResult> _downloadTile({
    required String style,
    required int z,
    required int x,
    required int y,
  }) async {
    try {
      final dir = await getTileCacheDirectory();
      final file = File('${dir.path}/${_sanitizeStyle(style)}/$z/$x/$y.png');

      if (file.existsSync()) return _TileResult.skipped;

      await file.parent.create(recursive: true);

      final url = _getTileUrl(style: style, z: z, x: x, y: y);
      final response = await _httpClient
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'CUNavigate/1.0 (Covenant University campus navigation)',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return _TileResult.downloaded;
      }

      debugPrint(
        'OfflineMapService: tile $z/$x/$y returned HTTP ${response.statusCode}',
      );
      return _TileResult.failed;
    } catch (e) {
      debugPrint('OfflineMapService: failed to download tile $z/$x/$y — $e');
      return _TileResult.failed;
    }
  }

  // ── Cleanup ───────────────────────────────────────────────

  void dispose() {
    _cancelRequested = true;
    _httpClient.close();
  }
}

// ── Internal enum ─────────────────────────────────────────────────────────────

enum _TileResult { downloaded, skipped, failed }

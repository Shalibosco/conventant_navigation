// lib/core/di/service_locator.dart

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_service.dart';
import '../services/network_service.dart';
import '../services/native_settings_service.dart';
import '../services/permissions_service.dart';

// ── Models
import '../../data/models/location_model.dart';

// ── Data Sources
import '../../data/datasources/local_location_data_source.dart';
import '../../data/datasources/local_info_data_source.dart';

// ── Repositories
import '../../data/repositories/location_repository.dart'; // Abstract
import '../../data/repositories/location_repository_impl.dart'; // Concrete
import '../../data/repositories/info_repository.dart'; // Abstract
import '../../data/repositories/info_repository_impl.dart'; // ✅ Concrete Added!

// ── Feature Services
import '../../features/navigation/services/location_service.dart';
import '../../features/navigation/services/route_service.dart';
import '../../features/navigation/services/offline_map_service.dart';
import '../../features/voice_assistant/services/speech_service.dart';
import '../../features/voice_assistant/services/text_to_speech_service.dart';
import '../../features/voice_assistant/services/voice_command_handler.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // ── External ──────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // ── Hive Boxes ────────────────────────────────────────────
  // Auto-recover from corrupted box (can happen if the previous process was
  // killed mid-write, e.g. during a debug session crash).
  Box<LocationModel> locationBox;
  try {
    locationBox = await Hive.openBox<LocationModel>('locations_box');
  } catch (e) {
    debugPrint('Hive box corrupted, clearing and reopening: $e');
    await Hive.deleteBoxFromDisk('locations_box');
    locationBox = await Hive.openBox<LocationModel>('locations_box');
  }

  // ── Core Services ─────────────────────────────────────────
  sl.registerLazySingleton<StorageService>(
    () => StorageService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<NetworkService>(() => NetworkService());
  sl.registerLazySingleton<NativeSettingsService>(
    () => NativeSettingsService(),
  );
  sl.registerLazySingleton<PermissionsService>(() => PermissionsService());

  // ── Data Sources ──────────────────────────────────────────
  sl.registerLazySingleton<LocalLocationDataSource>(
    () => LocalLocationDataSourceImpl(locationBox),
  );

  sl.registerLazySingleton<LocalInfoDataSource>(() => LocalInfoDataSource());

  // ── Repositories ──────────────────────────────────────────
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl<LocalLocationDataSource>()),
  );
  sl.registerLazySingleton<InfoRepository>(
    () => InfoRepositoryImpl(
      sl<LocalInfoDataSource>(),
    ), // ✅ Now it will recognize it!
  );

  // ── Feature Services ──────────────────────────────────────
  sl.registerLazySingleton<LocationService>(
    () => LocationService(sl<PermissionsService>()),
  );
  sl.registerLazySingleton<RouteService>(() => RouteService());
  sl.registerLazySingleton<OfflineMapService>(() => OfflineMapService());

  sl.registerLazySingleton<SpeechService>(() => SpeechService());
  sl.registerLazySingleton<TextToSpeechService>(() => TextToSpeechService());
  sl.registerLazySingleton<VoiceCommandHandler>(
    () => VoiceCommandHandler(sl<LocationRepository>()),
  );
}

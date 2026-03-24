// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_service.dart';
import '../services/network_service.dart';
import '../services/permissions_service.dart';
import '../../data/datasources/local_location_data_source.dart';
import '../../data/datasources/local_info_data_source.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/info_repository.dart';
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

  // ── Core Services ─────────────────────────────────────────
  sl.registerLazySingleton<StorageService>(
        () => StorageService(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<NetworkService>(() => NetworkService());
  sl.registerLazySingleton<PermissionsService>(() => PermissionsService());

  // ── Data Sources ──────────────────────────────────────────
  sl.registerLazySingleton<LocalLocationDataSource>(
        () => LocalLocationDataSource(),
  );
  sl.registerLazySingleton<LocalInfoDataSource>(
        () => LocalInfoDataSource(),
  );

  // ── Repositories ──────────────────────────────────────────
  sl.registerLazySingleton<LocationRepository>(
        () => LocationRepository(sl<LocalLocationDataSource>()),
  );
  sl.registerLazySingleton<InfoRepository>(
        () => InfoRepository(sl<LocalInfoDataSource>()),
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
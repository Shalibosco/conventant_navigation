// lib/core/error/exceptions.dart

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => 'LocationException: $message';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
  @override
  String toString() => 'PermissionException: $message';
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
  @override
  String toString() => 'StorageException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

class VoiceException implements Exception {
  final String message;
  const VoiceException(this.message);
  @override
  String toString() => 'VoiceException: $message';
}

class LocalizationException implements Exception {
  final String message;
  const LocalizationException(this.message);
  @override
  String toString() => 'LocalizationException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
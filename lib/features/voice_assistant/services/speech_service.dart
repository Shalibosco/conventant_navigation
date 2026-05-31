// lib/features/voice_assistant/services/speech_service.dart
// Native microphone via speech_to_text

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/exceptions.dart';

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastErrorCode = '';

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  String _normalizeLocale(String locale) =>
      locale.replaceAll('_', '-').toLowerCase();

  String? _bestLocaleMatch(String requestedLocale, List<LocaleName> available) {
    final requested = _normalizeLocale(requestedLocale);

    for (final locale in available) {
      if (_normalizeLocale(locale.localeId) == requested) {
        return locale.localeId;
      }
    }

    final requestedLanguage = requested.split('-').first;
    for (final locale in available) {
      if (_normalizeLocale(locale.localeId).startsWith('$requestedLanguage-') ||
          _normalizeLocale(locale.localeId) == requestedLanguage) {
        return locale.localeId;
      }
    }

    for (final locale in available) {
      if (_normalizeLocale(locale.localeId) == 'en-ng') {
        return locale.localeId;
      }
    }

    for (final locale in available) {
      if (_normalizeLocale(locale.localeId).startsWith('en-') ||
          _normalizeLocale(locale.localeId) == 'en') {
        return locale.localeId;
      }
    }

    return available.isNotEmpty ? available.first.localeId : null;
  }

  // ── Request mic permission then init ─────────────────────
  Future<bool> initialize() async {
    try {
      // Request native microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw const VoiceException(
          'Microphone permission denied. Please enable in Settings.',
        );
      }

      _isInitialized = await _stt.initialize(
        onError: (error) {
          debugPrint('STT error: ${error.errorMsg}');
          _lastErrorCode = error.errorMsg.toLowerCase();
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        debugLogging: false,
      );
      return _isInitialized;
    } catch (e) {
      if (e is VoiceException) rethrow;
      throw VoiceException('Speech init failed: $e');
    }
  }

  bool get _hasNetworkError =>
      _lastErrorCode.contains('error_network') ||
      _lastErrorCode.contains('error_server') ||
      _lastErrorCode.contains('error_server_disconnected');

  bool get _hasLanguageUnavailableError =>
      _lastErrorCode.contains('error_language_unavailable') ||
      _lastErrorCode.contains('error_language_not_supported');

  bool _hasUsableText(String? text) => text != null && text.trim().isNotEmpty;

  List<String> _candidateLocales(String preferred, List<LocaleName> available) {
    final out = <String>[];
    void addIfExists(String pattern) {
      final found = available
          .where(
            (l) => _normalizeLocale(l.localeId) == _normalizeLocale(pattern),
          )
          .map((l) => l.localeId);
      for (final item in found) {
        if (!out.contains(item)) out.add(item);
      }
    }

    void addFirstByPrefix(String prefix) {
      for (final locale in available) {
        final normalized = _normalizeLocale(locale.localeId);
        if (normalized == prefix || normalized.startsWith('$prefix-')) {
          if (!out.contains(locale.localeId)) out.add(locale.localeId);
          break;
        }
      }
    }

    out.add(preferred);
    addIfExists('en-NG');
    addIfExists('en-US');
    addIfExists('en-GB');
    addIfExists('en-AU');
    addFirstByPrefix('en');
    return out.toSet().toList();
  }

  Future<({String? finalText, String? partialText})> _listenOnce({
    required String localeId,
    required bool onDevice,
    void Function(String partial)? onPartialResult,
    void Function()? onListeningStarted,
  }) async {
    String? finalResult;
    String? latestPartial;

    if (_stt.isListening) {
      await _stt.cancel();
    }

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        if (_hasUsableText(result.recognizedWords)) {
          latestPartial = result.recognizedWords;
        }
        if (result.finalResult && _hasUsableText(result.recognizedWords)) {
          finalResult = result.recognizedWords;
        } else if (_hasUsableText(result.recognizedWords)) {
          onPartialResult?.call(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(
          seconds: AppConstants.voiceListenSeconds < 8
              ? 8
              : AppConstants.voiceListenSeconds,
        ),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        onDevice: onDevice,
        listenMode: ListenMode.search,
      ),
    );

    _isListening = true;
    onListeningStarted?.call();

    await Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return _stt.isListening;
    });

    return (finalText: finalResult, partialText: latestPartial);
  }

  // ── Listen using native mic ───────────────────────────────
  Future<String?> listen({
    required String langCode,
    void Function(String partial)? onPartialResult,
    void Function()? onListeningStarted,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) {
      throw const VoiceException(
        'Speech recognition not available on this device.',
      );
    }

    final locale = await resolveLocaleIdForLanguage(langCode);
    final available = await _stt.locales();
    final candidates = _candidateLocales(locale, available);
    String? bestPartial;
    _lastErrorCode = '';

    try {
      for (final candidate in candidates) {
        _lastErrorCode = '';
        final localResult = await _listenOnce(
          localeId: candidate,
          onDevice: true,
          onPartialResult: onPartialResult,
          onListeningStarted: onListeningStarted,
        );

        if (_hasUsableText(localResult.finalText)) {
          return localResult.finalText;
        }
        if (_hasUsableText(localResult.partialText)) {
          bestPartial ??= localResult.partialText;
        }

        // If local engine is unavailable or weak, retry same locale with network-enabled recognition.
        if (_hasLanguageUnavailableError ||
            _hasNetworkError ||
            !_hasUsableText(localResult.partialText)) {
          _lastErrorCode = '';
          final cloudResult = await _listenOnce(
            localeId: candidate,
            onDevice: false,
            onPartialResult: onPartialResult,
          );

          if (_hasUsableText(cloudResult.finalText)) {
            return cloudResult.finalText;
          }
          if (_hasUsableText(cloudResult.partialText)) {
            bestPartial ??= cloudResult.partialText;
          }
        }
      }

      if (_hasUsableText(bestPartial)) {
        return bestPartial;
      }

      if (_hasNetworkError) {
        throw const VoiceException(
          'Speech recognition network is unavailable. Check internet or install offline speech language pack.',
        );
      }

      return null;
    } catch (e) {
      throw VoiceException('Listening failed: $e');
    } finally {
      _isListening = false;
    }
  }

  Future<void> stop() async {
    await _stt.stop();
    _isListening = false;
  }

  Future<void> cancel() async {
    await _stt.cancel();
    _isListening = false;
  }

  Future<List<LocaleName>> availableLocales() async {
    if (!_isInitialized) await initialize();
    return _stt.locales();
  }

  Future<String> resolveLocaleIdForLanguage(String langCode) async {
    if (!_isInitialized) await initialize();
    final requested = AppConstants.sttLanguageCodes[langCode] ?? 'en_NG';
    final available = await _stt.locales();
    final resolved = _bestLocaleMatch(requested, available);
    if (resolved == null) {
      throw const VoiceException(
        'No speech recognition locale available on this device.',
      );
    }
    return resolved;
  }

  Future<({String requested, String resolved, bool fallback})> negotiateLocale(
    String langCode,
  ) async {
    final requested = AppConstants.sttLanguageCodes[langCode] ?? 'en_NG';
    final resolved = await resolveLocaleIdForLanguage(langCode);
    final fallback = _normalizeLocale(requested) != _normalizeLocale(resolved);
    return (requested: requested, resolved: resolved, fallback: fallback);
  }

  void dispose() => _stt.cancel();
}

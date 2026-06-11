// lib/features/voice_assistant/services/speech_service.dart
// Optimized native microphone via speech_to_text

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/exceptions.dart';

/// Result returned from a single listen attempt.
typedef ListenResult = ({String? finalText, String? partialText});

class SpeechService {
  // ── Internal STT instance ─────────────────────────────────
  final SpeechToText _stt = SpeechToText();

  // ── State ─────────────────────────────────────────────────
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastErrorCode = '';

  /// Guards against concurrent initialize() calls.
  Completer<bool>? _initCompleter;

  /// Locale list is fetched once and reused.
  List<LocaleName>? _cachedLocales;

  /// Prevents duplicate partial emissions to the caller.
  String? _lastEmittedPartial;

  /// Broadcast stream of every recognized word/phrase (partials + finals).
  final StreamController<String> _wordStreamController =
  StreamController<String>.broadcast();

  // ── Public getters ────────────────────────────────────────
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Stream of recognized words suitable for driving a voice-command UI.
  Stream<String> get recognizedWords => _wordStreamController.stream;

  // ── Locale helpers ────────────────────────────────────────
  String _normalizeLocale(String locale) =>
      locale.replaceAll('_', '-').toLowerCase();

  String? _bestLocaleMatch(String requestedLocale, List<LocaleName> available) {
    final requested = _normalizeLocale(requestedLocale);

    // 1. Exact match
    for (final locale in available) {
      if (_normalizeLocale(locale.localeId) == requested) {
        return locale.localeId;
      }
    }

    // 2. Same language prefix
    final requestedLanguage = requested.split('-').first;
    for (final locale in available) {
      final normalized = _normalizeLocale(locale.localeId);
      if (normalized.startsWith('$requestedLanguage-') ||
          normalized == requestedLanguage) {
        return locale.localeId;
      }
    }

    // 3. Nigerian English preference
    for (final locale in available) {
      if (_normalizeLocale(locale.localeId) == 'en-ng') return locale.localeId;
    }

    // 4. Any English
    for (final locale in available) {
      final normalized = _normalizeLocale(locale.localeId);
      if (normalized.startsWith('en-') || normalized == 'en') {
        return locale.localeId;
      }
    }

    return available.isNotEmpty ? available.first.localeId : null;
  }

  /// Returns a de-duplicated, priority-ordered list of locales to try.
  List<String> _candidateLocales(
      String preferred,
      List<LocaleName> available,
      ) {
    final out = <String>[];

    void addIfExists(String pattern) {
      for (final l in available) {
        if (_normalizeLocale(l.localeId) == _normalizeLocale(pattern)) {
          if (!out.contains(l.localeId)) out.add(l.localeId);
        }
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

  // ── Error classifiers ─────────────────────────────────────
  bool get _hasNetworkError =>
      _lastErrorCode.contains('error_network') ||
          _lastErrorCode.contains('error_server') ||
          _lastErrorCode.contains('error_server_disconnected');

  bool get _hasLanguageUnavailableError =>
      _lastErrorCode.contains('error_language_unavailable') ||
          _lastErrorCode.contains('error_language_not_supported');

  bool _hasUsableText(String? text) => text != null && text.trim().isNotEmpty;

  // ── Initialization ────────────────────────────────────────

  /// Requests microphone permission and initializes the STT engine.
  /// Concurrent calls are safely serialized via [_initCompleter].
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Queue concurrent callers behind the in-flight init.
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<bool>();

    try {
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw const VoiceException(
          'Microphone permission denied. Please enable it in Settings.',
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

      _initCompleter!.complete(_isInitialized);
      return _isInitialized;
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // allow retry after failure
      if (e is VoiceException) rethrow;
      throw VoiceException('Speech init failed: $e');
    }
  }

  // ── Locale cache ──────────────────────────────────────────

  /// Returns available locales, fetching from the platform only once.
  Future<List<LocaleName>> availableLocales() async {
    if (!_isInitialized) await initialize();
    _cachedLocales ??= await _stt.locales();
    return _cachedLocales!;
  }

  Future<String> resolveLocaleIdForLanguage(String langCode) async {
    if (!_isInitialized) await initialize();
    final requested = AppConstants.sttLanguageCodes[langCode] ?? 'en_NG';
    final available = await availableLocales(); // uses cache
    final resolved = _bestLocaleMatch(requested, available);
    if (resolved == null) {
      throw const VoiceException(
        'No speech recognition locale is available on this device.',
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

  // ── Core listen ───────────────────────────────────────────

  /// Single-attempt listen. Uses a [Completer] instead of a polling loop so
  /// the isolate is not woken every 150 ms.
  Future<ListenResult> _listenOnce({
    required String localeId,
    required bool onDevice,
    void Function(String partial)? onPartialResult,
    void Function()? onListeningStarted,
  }) async {
    final listenDuration = Duration(
      seconds: AppConstants.voiceListenSeconds < 8
          ? 8
          : AppConstants.voiceListenSeconds,
    );

    // Completer fires as soon as a final result arrives or the engine stops.
    final completer = Completer<void>();
    String? finalResult;
    String? latestPartial;

    if (_stt.isListening) await _stt.cancel();

    // Re-init callbacks so the completer is in scope.
    await _stt.initialize(
      onError: (error) {
        _lastErrorCode = error.errorMsg.toLowerCase();
        _isListening = false;
        if (!completer.isCompleted) completer.complete();
      },
      onStatus: (status) {
        debugPrint('STT status: $status');
        if (status == 'listening') {
          _isListening = true;
        } else if (status == 'done' || status == 'notListening') {
          _isListening = false;
          if (!completer.isCompleted) completer.complete();
        }
      },
    );

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (!_hasUsableText(words)) return;

        // Stream every unique partial to subscribers.
        if (words != _lastEmittedPartial) {
          _lastEmittedPartial = words;
          _wordStreamController.add(words);
          onPartialResult?.call(words);
        }

        latestPartial = words;

        if (result.finalResult) {
          finalResult = words;
          // Resolve early — no need to wait for the full timeout.
          if (!completer.isCompleted) completer.complete();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: listenDuration,
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        onDevice: onDevice,
        listenMode: ListenMode.search,
      ),
    );

    onListeningStarted?.call();

    await completer.future.timeout(
      listenDuration + const Duration(seconds: 3),
      onTimeout: () {
        _stt.cancel();
        _isListening = false;
      },
    );

    return (finalText: finalResult, partialText: latestPartial);
  }

  // ── Public listen API ─────────────────────────────────────

  /// Listens for speech and returns the recognized text.
  ///
  /// Strategy:
  ///   1. Try the preferred locale with on-device recognition.
  ///   2. If that fails, retry the same locale with cloud recognition.
  ///   3. Fall back to at most [_maxFallbackLocales] alternative locales.
  ///   4. Return the best partial if no final result was produced.
  static const int _maxFallbackLocales = 2;

  Future<String?> listen({
    required String langCode,
    void Function(String partial)? onPartialResult,
    void Function()? onListeningStarted,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) {
      throw const VoiceException(
        'Speech recognition is not available on this device.',
      );
    }

    final locale = await resolveLocaleIdForLanguage(langCode);
    final available = await availableLocales(); // cached
    final candidates = _candidateLocales(locale, available);

    String? bestPartial;
    _lastErrorCode = '';
    _lastEmittedPartial = null;

    int fallbacksUsed = 0;

    try {
      for (final candidate in candidates) {
        if (fallbacksUsed >= _maxFallbackLocales) break;
        if (candidate != candidates.first) fallbacksUsed++;

        _lastErrorCode = '';

        // ── Pass 1: on-device ─────────────────────────────
        final localResult = await _listenOnce(
          localeId: candidate,
          onDevice: true,
          onPartialResult: onPartialResult,
          onListeningStarted: onListeningStarted,
        );

        if (_hasUsableText(localResult.finalText)) {
          return localResult.finalText;
        }

        bestPartial ??= localResult.partialText;

        final shouldTryCloud = _hasLanguageUnavailableError ||
            _hasNetworkError ||
            !_hasUsableText(localResult.partialText);

        if (!shouldTryCloud) {
          // On-device engine worked but heard nothing — no point trying more
          // locales; the user simply didn't speak.
          break;
        }

        // ── Pass 2: cloud / network recognition ──────────
        _lastErrorCode = '';
        final cloudResult = await _listenOnce(
          localeId: candidate,
          onDevice: false,
          onPartialResult: onPartialResult,
        );

        if (_hasUsableText(cloudResult.finalText)) {
          return cloudResult.finalText;
        }

        bestPartial ??= cloudResult.partialText;

        // If cloud also failed with a network error there is no point
        // retrying further locales; they will face the same issue.
        if (_hasNetworkError) break;
      }

      if (_hasUsableText(bestPartial)) return bestPartial;

      if (_hasNetworkError) {
        throw const VoiceException(
          'Speech recognition network is unavailable. '
              'Check your internet connection or install an offline speech pack.',
        );
      }

      return null;
    } catch (e) {
      if (e is VoiceException) rethrow;
      throw VoiceException('Listening failed: $e');
    } finally {
      _isListening = false;
    }
  }

  // ── Control ───────────────────────────────────────────────
  Future<void> stop() async {
    await _stt.stop();
    _isListening = false;
  }

  Future<void> cancel() async {
    await _stt.cancel();
    _isListening = false;
  }

  // ── Cleanup ───────────────────────────────────────────────
  void dispose() {
    _stt.cancel();
    _wordStreamController.close();
  }
}
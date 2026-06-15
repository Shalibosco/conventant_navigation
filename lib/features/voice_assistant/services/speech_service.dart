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

  // ── On-device locale negotiation state ────────────────────
  /// Locales that have returned `error_language_unavailable` (or
  /// `error_language_not_supported`) when used with `onDevice: true`.
  /// Once a locale lands here we stop retrying it on-device for the
  /// lifetime of this service instance — the offline pack simply isn't
  /// installed for it, so retrying just produces more noise/errors.
  final Set<String> _onDeviceUnavailableLocales = {};

  /// The most recent locale that produced usable on-device results.
  /// We try this locale first for future on-device fallback attempts.
  String? _verifiedOnDeviceLocale;

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
  ///
  /// Order of priority:
  ///   1. A locale already verified to work for on-device recognition.
  ///   2. The resolved "preferred" locale.
  ///   3. en-NG / en-US / en-GB / en-AU, if present on the device.
  ///   4. *Every* other English-family locale the device reports (not just
  ///      the first one) — this matters because the first English locale
  ///      reported by the platform is often the system locale (e.g.
  ///      en-GB), which may not have an offline pack installed even though
  ///      it's "available" for cloud recognition.
  List<String> _candidateLocales(String preferred, List<LocaleName> available) {
    final out = <String>[];

    void addIfExists(String pattern) {
      for (final l in available) {
        if (_normalizeLocale(l.localeId) == _normalizeLocale(pattern)) {
          if (!out.contains(l.localeId)) out.add(l.localeId);
        }
      }
    }

    void addAllByPrefix(String prefix) {
      for (final locale in available) {
        final normalized = _normalizeLocale(locale.localeId);
        if (normalized == prefix || normalized.startsWith('$prefix-')) {
          if (!out.contains(locale.localeId)) out.add(locale.localeId);
        }
      }
    }

    // A locale that has already proven to work on-device is the safest bet,
    // so it goes first if it's still in the available list.
    if (_verifiedOnDeviceLocale != null) {
      for (final l in available) {
        if (l.localeId == _verifiedOnDeviceLocale) {
          if (!out.contains(l.localeId)) out.add(l.localeId);
        }
      }
    }

    out.add(preferred);
    addIfExists('en-NG');
    addIfExists('en-US');
    addIfExists('en-GB');
    addIfExists('en-AU');
    addAllByPrefix('en');
    return out.toSet().toList();
  }

  /// True once every English-family locale the device reports has already
  /// failed on-device recognition with `error_language_unavailable`. When
  /// this is the case, there's no point attempting on-device recognition
  /// again this session — every attempt would just fail the same way.
  bool _onDeviceLikelyUnsupported(List<LocaleName> available) {
    final englishLocales = available
        .map((l) => l.localeId)
        .where((id) => _normalizeLocale(id).startsWith('en'))
        .toSet();

    if (englishLocales.isEmpty) return false;
    return englishLocales.every(_onDeviceUnavailableLocales.contains);
  }

  /// Records the outcome of an on-device attempt so future calls can pick
  /// better candidates and avoid known-bad locales.
  void _recordOnDeviceOutcome(String localeId, {required bool usable}) {
    if (usable) {
      _verifiedOnDeviceLocale = localeId;
      _onDeviceUnavailableLocales.remove(localeId);
    } else if (_hasLanguageUnavailableError) {
      _onDeviceUnavailableLocales.add(localeId);
      if (_verifiedOnDeviceLocale == localeId) {
        _verifiedOnDeviceLocale = null;
      }
    }
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
    const listenDuration = Duration(
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
  ///   1. Try the preferred locale with cloud recognition first.
  ///   2. Retry the same locale with on-device recognition when useful —
  ///      unless that locale is already known to lack an offline pack.
  ///   3. Fall back across available English locales before giving up.
  ///   4. Return the best partial if no final result was produced.
  static const int _maxFallbackLocales = 5;

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

    try {
      for (final candidate in candidates.take(_maxFallbackLocales)) {
        _lastErrorCode = '';

        // Cloud recognition is more reliable across Android devices when
        // Nigerian English or offline packs are unavailable.
        final cloudResult = await _listenOnce(
          localeId: candidate,
          onDevice: false,
          onPartialResult: onPartialResult,
          onListeningStarted: onListeningStarted,
        );

        if (_hasUsableText(cloudResult.finalText)) {
          return cloudResult.finalText;
        }

        bestPartial ??= cloudResult.partialText;

        if (_hasUsableText(bestPartial)) {
          break;
        }

        // If cloud cannot hear anything, try on-device for this locale
        // before moving to the next candidate — but only if we haven't
        // already proven this locale lacks an offline pack, and only if
        // on-device recognition isn't already known to be a dead end for
        // every English locale on this device.
        final shouldTryOnDevice =
            !_onDeviceUnavailableLocales.contains(candidate) &&
                !_onDeviceLikelyUnsupported(available) &&
                (_hasLanguageUnavailableError ||
                    _hasNetworkError ||
                    !_hasUsableText(cloudResult.partialText));

        if (!shouldTryOnDevice) continue;

        _lastErrorCode = '';
        final localResult = await _listenOnce(
          localeId: candidate,
          onDevice: true,
          onPartialResult: onPartialResult,
        );

        _recordOnDeviceOutcome(
          candidate,
          usable: _hasUsableText(localResult.finalText) ||
              _hasUsableText(localResult.partialText),
        );

        if (_hasUsableText(localResult.finalText)) {
          return localResult.finalText;
        }

        bestPartial ??= localResult.partialText;
        if (_hasUsableText(bestPartial)) break;
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
// lib/features/voice_assistant/services/text_to_speech_service.dart
// Native speaker via flutter_tts

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/exceptions.dart';

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();

  // ── State ─────────────────────────────────────────────────
  bool _isReady = false;
  bool _isSpeaking = false;
  String _langCode = 'en';

  /// Guards against concurrent initialize() calls.
  Completer<void>? _initCompleter;

  /// Cached language list — fetched from the platform once.
  List<String>? _cachedLanguages;

  bool get isSpeaking => _isSpeaking;
  bool get isReady => _isReady;

  // ── Initialization ────────────────────────────────────────

  /// Initializes the TTS engine for [langCode].
  ///
  /// Re-initialization only runs when [langCode] changes or the engine has
  /// not been set up yet. Concurrent calls are serialized via [_initCompleter].
  Future<void> initialize({String langCode = 'en'}) async {
    if (_isReady && _langCode == langCode) return;

    // Queue concurrent callers behind the in-flight init.
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.48); // natural pace
      await _tts.setVolume(1.0); // full volume
      await _tts.setPitch(1.05); // slightly warm pitch

      // Register callbacks once — not on every initialize() call.
      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS error: $msg');
      });

      await _applyLanguage(langCode);

      _isReady = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // allow retry after failure
      throw VoiceException('TTS init failed: $e');
    } finally {
      // Always clear the completer so future calls go through normally.
      _initCompleter = null;
    }
  }

  // ── Language ──────────────────────────────────────────────

  /// Updates the active TTS language, falling back to en-NG if the requested
  /// locale is unavailable on this device.
  Future<void> setLanguage(String langCode) async {
    if (_langCode == langCode && _isReady) return; // no-op if already set
    await _applyLanguage(langCode);
  }

  Future<void> _applyLanguage(String langCode) async {
    _langCode = langCode;
    final code = AppConstants.ttsLanguageCodes[langCode] ?? 'en-NG';

    // Check against cached language list before making a platform call.
    final supported = await _isSupportedLanguage(code);
    if (supported) {
      await _tts.setLanguage(code);
    } else {
      debugPrint('TTS: $code not available, falling back to en-NG');
      await _tts.setLanguage('en-NG');
    }
  }

  /// Returns true if [code] is in the device's available TTS language list.
  Future<bool> _isSupportedLanguage(String code) async {
    final langs = await availableLanguages();
    final normalized = code.toLowerCase();
    // Match both exact (en-NG) and prefix (en) forms.
    return langs.any(
      (l) =>
          l.toLowerCase() == normalized ||
          l.toLowerCase().startsWith('${normalized.split('-').first}-'),
    );
  }

  // ── Speak ─────────────────────────────────────────────────

  /// Speaks [text] through the device speaker.
  ///
  /// Stops any ongoing speech first. Silently ignores blank input.
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (!_isReady) await initialize(langCode: _langCode);

    try {
      if (_isSpeaking) await stop();
      _isSpeaking = true;
      await _tts
          .speak(trimmed)
          .timeout(
            _speakTimeoutFor(trimmed),
            onTimeout: () async {
              debugPrint('TTS speak timed out; resetting voice state.');
              await stop();
              return 0;
            },
          );
    } catch (e) {
      throw VoiceException('TTS speak failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  Duration _speakTimeoutFor(String text) {
    final seconds = (text.length / 12).ceil().clamp(4, 20).toInt();
    return Duration(seconds: seconds);
  }

  // ── Playback control ──────────────────────────────────────

  Future<void> stop() async {
    try {
      await _tts.stop();
    } finally {
      _isSpeaking = false; // always reset even if stop() throws
    }
  }

  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (e) {
      debugPrint('TTS pause failed: $e');
    }
  }

  // ── Language list ─────────────────────────────────────────

  /// Returns the device's available TTS languages, fetching from the platform
  /// only once per app lifecycle.
  Future<List<String>> availableLanguages() async {
    if (_cachedLanguages != null) return _cachedLanguages!;

    final raw = await _tts.getLanguages;

    // flutter_tts returns dynamic — safely cast each item individually.
    _cachedLanguages = (raw as List<dynamic>).whereType<String>().toList();

    return _cachedLanguages!;
  }

  // ── Cleanup ───────────────────────────────────────────────

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isReady = false;
    _isSpeaking = false;
  }
}

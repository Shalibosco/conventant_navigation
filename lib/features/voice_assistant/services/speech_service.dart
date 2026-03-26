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

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  // ── Request mic permission then init ─────────────────────
  Future<bool> initialize() async {
    try {
      // Request native microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        throw const VoiceException(
            'Microphone permission denied. Please enable in Settings.');
      }

      _isInitialized = await _stt.initialize(
        onError: (error) {
          debugPrint('STT error: ${error.errorMsg}');
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

  // ── Listen using native mic ───────────────────────────────
  Future<String?> listen({
    required String langCode,
    void Function(String partial)? onPartialResult,
    void Function()? onListeningStarted,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) {
      throw const VoiceException('Speech recognition not available on this device.');
    }

    final locale = AppConstants.sttLanguageCodes[langCode] ?? 'en_NG';
    String? finalResult;

    try {
      _isListening = true;
      onListeningStarted?.call();

      await _stt.listen(
        localeId: locale,
        listenFor: Duration(seconds: AppConstants.voiceListenSeconds),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            finalResult = result.recognizedWords;
          } else {
            onPartialResult?.call(result.recognizedWords);
          }
        },
      );

      // Wait until STT signals done
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 150));
        return _stt.isListening;
      });

      return finalResult;
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

  void dispose() => _stt.cancel();
}
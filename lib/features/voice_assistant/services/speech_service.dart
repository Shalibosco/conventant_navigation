// lib/features/voice_assistant/services/speech_service.dart

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

  Future<bool> initialize() async {
    try {
      _isInitialized = await _stt.initialize(
        onError: (error) {
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      throw VoiceException('Failed to initialize speech recognition: $e');
    }
  }

  Future<String?> listen({
    required String langCode,
    Duration duration = const Duration(seconds: 5),
    void Function(String partial)? onPartialResult,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) {
      throw const VoiceException('Speech recognition not available on device');
    }

    final sttLang = AppConstants.sttLanguageCodes[langCode] ?? 'en_NG';
    String? finalResult;

    try {
      _isListening = true;
      await _stt.listen(
        localeId: sttLang,
        listenFor: duration,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            finalResult = result.recognizedWords;
          } else {
            onPartialResult?.call(result.recognizedWords);
          }
        },
        cancelOnError: true,
        // listenMode removed in v7 — confirmation mode is now the default
      );

      // Wait for listening to finish
      await Future.delayed(duration + const Duration(milliseconds: 500));
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

  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) await initialize();
    return _stt.locales();
  }

  void dispose() {
    _stt.cancel();
  }
}
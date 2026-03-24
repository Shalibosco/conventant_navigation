// lib/features/voice_assistant/services/text_to_speech_service.dart

import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/exceptions.dart';

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentLang = 'en';

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize({String langCode = 'en'}) async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      await setLanguage(langCode);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((_) => _isSpeaking = false);

      _isInitialized = true;
    } catch (e) {
      throw VoiceException('Failed to initialize TTS: $e');
    }
  }

  Future<void> setLanguage(String langCode) async {
    _currentLang = langCode;
    final ttsCode = AppConstants.ttsLanguageCodes[langCode] ?? 'en-NG';
    await _tts.setLanguage(ttsCode);
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize(langCode: _currentLang);
    if (text.trim().isEmpty) return;

    try {
      if (_isSpeaking) await stop();
      await _tts.speak(text);
    } catch (e) {
      throw VoiceException('TTS speak failed: $e');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  Future<List<dynamic>> getAvailableLanguages() async {
    final languages = await _tts.getLanguages;
    // 👇Explicitly cast dynamic to a List
    return languages as List<dynamic>;
  }
  void dispose() {
    _tts.stop();
  }
}
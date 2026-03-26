// lib/features/voice_assistant/services/text_to_speech_service.dart
// Native speaker via flutter_tts

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/exceptions.dart';

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _isReady   = false;
  bool _isSpeaking = false;
  String _langCode = 'en';

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize({String langCode = 'en'}) async {
    try {
      // Native speaker settings
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.48);   // Natural pace
      await _tts.setVolume(1.0);         // Full volume
      await _tts.setPitch(1.05);         // Slightly warm pitch

      await setLanguage(langCode);

      _tts.setStartHandler(() { _isSpeaking = true; });
      _tts.setCompletionHandler(() { _isSpeaking = false; });
      _tts.setCancelHandler(() { _isSpeaking = false; });
      _tts.setErrorHandler((_) { _isSpeaking = false; });

      _isReady = true;
    } catch (e) {
      throw VoiceException('TTS init failed: $e');
    }
  }

  Future<void> setLanguage(String langCode) async {
    _langCode = langCode;
    final code = AppConstants.ttsLanguageCodes[langCode] ?? 'en-NG';
    try {
      await _tts.setLanguage(code);
    } catch (_) {
      // Fallback to English if language not supported on device
      await _tts.setLanguage('en-NG');
      debugPrint('TTS: $code not available, falling back to en-NG');
    }
  }

  // ── Speak through native phone speaker ───────────────────
  Future<void> speak(String text) async {
    if (!_isReady) await initialize(langCode: _langCode);
    if (text.trim().isEmpty) return;
    try {
      if (_isSpeaking) await stop();
      await _tts.speak(text);
    } catch (e) {
      throw VoiceException('TTS speak failed: $e');
    }
  }

  Future<void> stop() async { await _tts.stop(); _isSpeaking = false; }
  Future<void> pause() async { await _tts.pause(); }

  // ✅ Fixed: Added explicit casting to satisfy Dart's strict typing
  Future<List<dynamic>> availableLanguages() async {
    final result = await _tts.getLanguages;
    return result as List<dynamic>;
  }

  void dispose() { _tts.stop(); }
}
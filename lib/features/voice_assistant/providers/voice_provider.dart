// lib/features/voice_assistant/providers/voice_provider.dart

import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/voice_command_handler.dart';
import '../../../core/di/service_locator.dart';

enum VoiceState { idle, listening, processing, speaking, error }

class VoiceProvider extends ChangeNotifier {
  final SpeechService _speechService = sl<SpeechService>();
  final TextToSpeechService _ttsService = sl<TextToSpeechService>();
  final VoiceCommandHandler _commandHandler = sl<VoiceCommandHandler>();

  VoiceState _state = VoiceState.idle;
  String _partialText = '';
  String _recognizedText = '';
  String _responseText = '';
  String _errorMessage = '';
  String _languageWarning = '';
  VoiceCommand? _lastCommand;
  String _currentLang = 'en';

  // ── Getters ───────────────────────────────────────────────
  VoiceState get state => _state;
  String get partialText => _partialText;
  String get recognizedText => _recognizedText;
  String get responseText => _responseText;
  String get errorMessage => _errorMessage;
  String get languageWarning => _languageWarning;
  VoiceCommand? get lastCommand => _lastCommand;
  String get currentLanguageCode => _currentLang;
  bool get isListening => _state == VoiceState.listening;
  bool get isSpeaking => _state == VoiceState.speaking;
  bool get isIdle => _state == VoiceState.idle;
  bool get isProcessing => _state == VoiceState.processing;

  // Callback so MapScreen can react to resolved voice commands
  void Function(VoiceCommand)? onCommandResolved;

  // ── Initialize ────────────────────────────────────────────
  Future<void> initialize(String langCode) async {
    _currentLang = langCode;
    await _ttsService.initialize(langCode: langCode);
    await _speechService.initialize();
    await _refreshLocaleWarning();
  }

  Future<void> setLanguage(String langCode) async {
    _currentLang = langCode;
    await _ttsService.setLanguage(langCode);
    await _refreshLocaleWarning();
  }

  // ── Start listening ───────────────────────────────────────
  Future<void> startListening() async {
    if (_state != VoiceState.idle) return;

    _setState(VoiceState.listening);
    _partialText = '';
    _recognizedText = '';
    _errorMessage = '';

    try {
      final result = await _speechService.listen(
        langCode: _currentLang,
        onPartialResult: (partial) {
          _partialText = partial;
          notifyListeners();
        },
      );

      if (result == null || result.trim().isEmpty) {
        _responseText = _currentLang == 'yo'
            ? 'Mi ò gbọ́ dáadáa. Jọwọ gbìyànjú lẹ́ẹ̀kansi ní ohun kedere.'
            : _currentLang == 'ig'
            ? 'Anụrụ m ya nke ọma. Biko kwuo ọzọ nke ọma.'
            : _currentLang == 'pidgin'
            ? 'I no hear am well. Abeg talk am again clear.'
            : 'I did not catch that. Please speak clearly and try again.';
        _setState(VoiceState.idle);
        return;
      }

      _recognizedText = result;
      _setState(VoiceState.processing);
      await _processCommand(result);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(VoiceState.error);
      await Future<void>.delayed(const Duration(seconds: 2));
      _setState(VoiceState.idle);
    }
  }

  // ── Process recognized text ───────────────────────────────
  Future<void> _processCommand(String text) async {
    try {
      final command = await _commandHandler.process(text, _currentLang);
      _lastCommand = command;
      onCommandResolved?.call(command);

      final response = _commandHandler.buildResponse(command, _currentLang);
      _responseText = response;
      _setState(VoiceState.speaking);

      await _ttsService.speak(response);
      _setState(VoiceState.idle);
    } catch (e) {
      _errorMessage = 'Processing error: $e';
      _setState(VoiceState.error);
      await Future<void>.delayed(const Duration(seconds: 2));
      _setState(VoiceState.idle);
    }
  }

  Future<void> _refreshLocaleWarning() async {
    try {
      final report = await _speechService.negotiateLocale(_currentLang);
      final nextWarning = report.fallback
          ? 'Voice language fallback: using ${report.resolved}. Install offline speech pack for best results.'
          : '';
      if (_languageWarning != nextWarning) {
        _languageWarning = nextWarning;
        notifyListeners();
      }
    } catch (_) {
      const nextWarning = 'Speech recognition is not available on this device.';
      if (_languageWarning != nextWarning) {
        _languageWarning = nextWarning;
        notifyListeners();
      }
    }
  }

  // ── Stop ─────────────────────────────────────────────────
  Future<void> stopListening() async {
    await _speechService.stop();
    await _ttsService.stop();
    _setState(VoiceState.idle);
  }

  // ── Speak directly (for nav instructions) ────────────────
  // Skips if user is actively speaking or processing a command.
  Future<void> speak(String text) async {
    if (_state == VoiceState.listening || _state == VoiceState.processing) {
      return;
    }
    _setState(VoiceState.speaking);
    await _ttsService.speak(text);
    _setState(VoiceState.idle);
  }

  void _setState(VoiceState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

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
  VoiceCommand? _lastCommand;
  String _currentLang = 'en';

  // ── Getters ───────────────────────────────────────────────
  VoiceState get state => _state;
  String get partialText => _partialText;
  String get recognizedText => _recognizedText;
  String get responseText => _responseText;
  String get errorMessage => _errorMessage;
  VoiceCommand? get lastCommand => _lastCommand;
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
  }

  Future<void> setLanguage(String langCode) async {
    _currentLang = langCode;
    await _ttsService.setLanguage(langCode);
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
        _setState(VoiceState.idle);
        return;
      }

      _recognizedText = result;
      _setState(VoiceState.processing);
      await _processCommand(result);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(VoiceState.error);
      await Future.delayed(const Duration(seconds: 2));
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
      await Future.delayed(const Duration(seconds: 2));
      _setState(VoiceState.idle);
    }
  }

  // ── Stop ─────────────────────────────────────────────────
  Future<void> stopListening() async {
    await _speechService.stop();
    await _ttsService.stop();
    _setState(VoiceState.idle);
  }

  // ── Speak directly (for nav instructions) ────────────────
  Future<void> speak(String text) async {
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
// lib/features/voice_assistant/providers/voice_provider.dart

import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/voice_command_handler.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/native_settings_service.dart';

enum VoiceState { idle, listening, processing, speaking, error }

class VoiceProvider extends ChangeNotifier {
  final SpeechService _speechService = sl<SpeechService>();
  final TextToSpeechService _ttsService = sl<TextToSpeechService>();
  final VoiceCommandHandler _commandHandler = sl<VoiceCommandHandler>();
  final NativeSettingsService _nativeSettingsService =
      sl<NativeSettingsService>();

  VoiceState _state = VoiceState.idle;
  String _partialText = '';
  String _recognizedText = '';
  String _responseText = '';
  String _errorMessage = '';
  String _languageWarning = '';
  VoiceCommand? _lastCommand;
  String _currentLang = 'en';
  int _listenSession = 0;
  bool _disposed = false;

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
  bool get canOpenOfflineSpeechSettings =>
      _nativeSettingsService.canOpenSpeechSettings;

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

    final session = ++_listenSession;
    _partialText = '';
    _recognizedText = '';
    _responseText = '';
    _errorMessage = '';
    await _ttsService.stop();
    _setState(VoiceState.listening);

    try {
      final result = await _speechService.listen(
        langCode: _currentLang,
        onPartialResult: (partial) {
          if (!_isActiveSession(session)) return;
          if (partial.trim().isEmpty) return;
          _partialText = partial;
          notifyListeners();
        },
      );

      if (!_isActiveSession(session)) return;

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
      await _processCommand(result, session);
    } catch (e) {
      if (!_isActiveSession(session)) return;
      _errorMessage = e.toString();
      _setState(VoiceState.error);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_isActiveSession(session)) {
        _setState(VoiceState.idle);
      }
    }
  }

  // ── Process recognized text ───────────────────────────────
  Future<void> _processCommand(String text, int session) async {
    try {
      final command = await _commandHandler.process(text, _currentLang);
      if (!_isActiveSession(session)) return;
      _lastCommand = command;

      final response = _commandHandler.buildResponse(command, _currentLang);
      _responseText = response;
      _setState(VoiceState.speaking);

      onCommandResolved?.call(command);
      try {
        await _ttsService.speak(response);
      } finally {
        if (_isActiveSession(session)) {
          _setState(VoiceState.idle);
        }
      }
    } catch (e) {
      if (!_isActiveSession(session)) return;
      _errorMessage = 'Processing error: $e';
      _setState(VoiceState.error);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_isActiveSession(session)) {
        _setState(VoiceState.idle);
      }
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
    _listenSession++;
    await _speechService.stop();
    await _ttsService.stop();
    _setState(VoiceState.idle);
  }

  Future<bool> openOfflineSpeechSettings() async {
    try {
      final opened = await _nativeSettingsService.openVoiceInputSettings();
      if (!opened) {
        _errorMessage =
            'Open Android voice input settings and install offline speech recognition for your language.';
        notifyListeners();
      }
      return opened;
    } catch (e) {
      _errorMessage = 'Could not open speech settings: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Speak directly (for nav instructions) ────────────────
  // Skips if user is actively speaking or processing a command.
  Future<void> speak(String text) async {
    if (_state == VoiceState.listening || _state == VoiceState.processing) {
      return;
    }
    _setState(VoiceState.speaking);
    try {
      await _ttsService.speak(text);
    } finally {
      _setState(VoiceState.idle);
    }
  }

  void _setState(VoiceState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  bool _isActiveSession(int session) {
    return !_disposed && session == _listenSession;
  }

  @override
  void dispose() {
    _disposed = true;
    _listenSession++;
    _speechService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

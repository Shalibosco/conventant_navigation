import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/app_constants.dart';  // Add this

class VoiceProvider extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastRecognized = '';
  String _language = 'en-US';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastRecognized => _lastRecognized;

  VoiceProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _speech.initialize();
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> startListening() async {
    if (!_isListening && _speech.isAvailable) {
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastRecognized = result.recognizedWords;
            _processCommand(_lastRecognized);
            _isListening = false;
            notifyListeners();
          }
        },
        localeId: _language,
        listenFor: const Duration(seconds: 10),
        listenOptions: SpeechListenOptions(  // Fixed deprecated parameters
          cancelOnError: true,
          partialResults: true,
        ),
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    if (!_isSpeaking) {
      _isSpeaking = true;
      notifyListeners();

      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);

      _isSpeaking = false;
      notifyListeners();
    }
  }

  void setLanguage(String language) {
    _language = language;
    _tts.setLanguage(language);
    notifyListeners();
  }

  void _processCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Process navigation commands
    if (lowerCommand.contains('navigate to') || lowerCommand.contains('where is')) {
      for (final location in AppConstants.campusLocations.keys) {
        if (lowerCommand.contains(location)) {
          final locationData = AppConstants.campusLocations[location];
          if (locationData != null) {
            speak('Navigating to ${locationData['name']}');
            // Trigger navigation
            return;
          }
        }
      }
    }

    // Process general commands
    if (lowerCommand.contains('help')) {
      speak('I can help you navigate to locations, find buildings, or give directions.');
    } else if (lowerCommand.contains('your name')) {
      speak('I am your Covenant University navigation assistant.');
    } else {
      speak('I heard: $command. How can I help you?');
    }
  }
}
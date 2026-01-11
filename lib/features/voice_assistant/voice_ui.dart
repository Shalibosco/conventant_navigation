import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'voice_pro.dart';

class VoiceAssistantButton extends StatefulWidget {
  const VoiceAssistantButton({super.key});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final voiceProvider = Provider.of<VoiceProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded && voiceProvider.lastRecognized.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              voiceProvider.lastRecognized,
              style: const TextStyle(fontSize: 14),
            ),
          ),

        FloatingActionButton(
          heroTag: 'voice',
          onPressed: () async {
            if (!voiceProvider.isListening) {
              await voiceProvider.startListening();
            } else {
              await voiceProvider.stopListening();
            }

            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          backgroundColor: voiceProvider.isListening ? Colors.red : Colors.blue,
          child: voiceProvider.isListening
              ? const Icon(Icons.stop, color: Colors.white)
              : const Icon(Icons.mic, color: Colors.white),
        ),
      ],
    );
  }
}
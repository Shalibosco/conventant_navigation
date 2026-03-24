// lib/features/voice_assistant/widgets/voice_ui.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/voice_provider.dart';
import '../../../core/theme/app_theme.dart';

class VoiceUI extends StatelessWidget {
  const VoiceUI({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceProvider>();
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Status label ─────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStatusText(voiceProvider, theme),
        ),

        const SizedBox(height: 10),

        // ── Mic button ────────────────────────────────────────
        GestureDetector(
          onTap: () {
            if (voiceProvider.isListening) {
              voiceProvider.stopListening();
            } else if (voiceProvider.isIdle) {
              voiceProvider.startListening();
            }
          },
          child: _MicButton(state: voiceProvider.state),
        ),
      ],
    );
  }

  Widget _buildStatusText(VoiceProvider provider, ThemeData theme) {
    String text;
    Color color;

    switch (provider.state) {
      case VoiceState.listening:
        text = provider.partialText.isNotEmpty
            ? '"${provider.partialText}"'
            : 'Listening...';
        color = AppTheme.voiceListeningColor;
        break;
      case VoiceState.processing:
        text = 'Processing...';
        color = AppTheme.primaryColor;
        break;
      case VoiceState.speaking:
        text = provider.responseText.isNotEmpty
            ? provider.responseText
            : 'Speaking...';
        color = AppTheme.accentColor;
        break;
      case VoiceState.error:
        text = 'Try again';
        color = AppTheme.errorColor;
        break;
      default:
        text = 'Tap mic to speak';
        color = theme.colorScheme.onSurface.withOpacity(0.6);
    }

    return Container(
      key: ValueKey(provider.state),
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Animated mic button ────────────────────────────────────
class _MicButton extends StatelessWidget {
  final VoiceState state;

  const _MicButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isListening  = state == VoiceState.listening;
    final isSpeaking   = state == VoiceState.speaking;
    final isProcessing = state == VoiceState.processing;

    final Color bgColor;
    final IconData icon;

    if (isListening) {
      bgColor = AppTheme.voiceListeningColor;
      icon = Icons.mic_rounded;
    } else if (isSpeaking) {
      bgColor = AppTheme.accentColor;
      icon = Icons.volume_up_rounded;
    } else if (isProcessing) {
      bgColor = AppTheme.primaryColor;
      icon = Icons.hourglass_top_rounded;
    } else {
      bgColor = AppTheme.primaryColor;
      icon = Icons.mic_none_rounded;
    }

    Widget button = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.5),
            blurRadius: isListening ? 20 : 10,
            spreadRadius: isListening ? 4 : 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );

    if (isListening) {
      button = button
          .animate(onPlay: (c) => c.repeat())
          .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.12, 1.12),
        duration: 700.ms,
        curve: Curves.easeInOut,
      )
          .then()
          .scale(
        begin: const Offset(1.12, 1.12),
        end: const Offset(1.0, 1.0),
        duration: 700.ms,
        curve: Curves.easeInOut,
      );
    }

    if (isProcessing) {
      button = button
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 1200.ms);
    }

    return button;
  }
}
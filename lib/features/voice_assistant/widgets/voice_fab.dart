// lib/features/voice_assistant/widgets/voice_fab.dart
// The main voice button — native mic + speaker

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/voice_provider.dart';
import '../../multilingual/localization/app_localization.dart';
import '../../../core/theme/app_theme.dart';

class VoiceFab extends StatelessWidget {
  const VoiceFab({super.key});

  @override
  Widget build(BuildContext context) {
    final voice = context.watch<VoiceProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status pill
        AnimatedSwitcher(
          duration: 250.ms,
          child: _StatusPill(voice: voice),
        ),
        const SizedBox(height: 10),
        // Mic button
        GestureDetector(
          onTap: () {
            if (voice.isListening) {
              voice.stopListening();
            } else if (voice.isIdle) {
              voice.startListening();
            }
          },
          child: _MicButton(state: voice.state),
        ),
      ],
    );
  }
}

// ── Status pill ────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final VoiceProvider voice;
  const _StatusPill({required this.voice});

  @override
  Widget build(BuildContext context) {
    String text;
    Color bg;
    const textColor = Colors.white;

    switch (voice.state) {
      case VoiceState.listening:
        text = voice.partialText.isNotEmpty
            ? '"${voice.partialText}"'
            : context.t('voice_listening');
        bg = AppTheme.voiceListening;
        break;
      case VoiceState.processing:
        text = context.t('voice_processing');
        bg = AppTheme.cuNavy;
        break;
      case VoiceState.speaking:
        text = voice.responseText.isNotEmpty
            ? voice.responseText.length > 50
                  ? '${voice.responseText.substring(0, 50)}...'
                  : voice.responseText
            : context.t('voice_speaking');
        bg = AppTheme.navGreen;
        break;
      case VoiceState.error:
        text = context.t('voice_error');
        bg = AppTheme.errorRed;
        break;
      default:
        text = voice.languageWarning.isNotEmpty
            ? voice.languageWarning
            : context.t('voice_tap_to_speak');
        bg = Colors.black.withValues(alpha: 0.65);
    }

    return Container(
      key: ValueKey(voice.state),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
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
    final isListening = state == VoiceState.listening;
    final isSpeaking = state == VoiceState.speaking;
    final isProcessing = state == VoiceState.processing;

    final Color bg;
    final IconData icon;

    if (isListening) {
      bg = AppTheme.voiceListening;
      icon = Icons.mic_rounded;
    } else if (isSpeaking) {
      bg = AppTheme.navGreen;
      icon = Icons.volume_up_rounded;
    } else if (isProcessing) {
      bg = AppTheme.cuGold;
      icon = Icons.hourglass_top_rounded;
    } else {
      bg = AppTheme.cuNavy;
      icon = Icons.mic_none_rounded;
    }

    Widget btn = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withValues(alpha: 0.8)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: isListening ? 0.7 : 0.4),
            blurRadius: isListening ? 24 : 12,
            spreadRadius: isListening ? 6 : 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );

    // Pulse when listening
    if (isListening) {
      btn = btn
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 700.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.1, 1.1),
            end: const Offset(1, 1),
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }
    // Spin when processing
    if (isProcessing) {
      btn = btn.animate(onPlay: (c) => c.repeat()).rotate(duration: 1200.ms);
    }
    // Bounce when speaking
    if (isSpeaking) {
      btn = btn
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 500.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.05, 1.05),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeInOut,
          );
    }

    return btn;
  }
}

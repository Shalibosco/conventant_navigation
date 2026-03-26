// lib/features/voice_assistant/screens/voice_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/voice_provider.dart';
import '../widgets/voice_ui.dart';
import '../../multilingual/providers/language_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceProvider = context.watch<VoiceProvider>();
    final langProvider = context.watch<LanguageProvider>();

    // ✅ Re-evaluated fallback language name logic safely
    final languageName = AppConstants.languageNames[langProvider.langCode] ?? 'English';

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Assistant')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Icon ──────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.cuNavy.withValues(alpha: 0.1), // ✅ Fixed withValues & cuNavy
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assistant_rounded,
                  color: AppTheme.cuNavy, // ✅ Fixed cuNavy
                  size: 40,
                ),
              ).animate().fadeIn(duration: 400.ms).scale(),

              const SizedBox(height: 20),

              Text(
                'CU Voice Assistant',
                style: theme.textTheme.headlineSmall,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Speak in $languageName',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55), // ✅ Fixed withValues
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              // ── Voice UI (mic button) ─────────────────────
              const VoiceUI(),

              const SizedBox(height: 40),

              // ── Recognized text bubble ────────────────────
              if (voiceProvider.recognizedText.isNotEmpty)
                _TextBubble(
                  label: 'You said',
                  text: voiceProvider.recognizedText,
                  color: AppTheme.cuNavy, // ✅ Fixed cuNavy
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),

              if (voiceProvider.responseText.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TextBubble(
                  label: 'Assistant',
                  text: voiceProvider.responseText,
                  color: AppTheme.navGreen, // ✅ Fixed navGreen
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
              ],

              const Spacer(),

              // ── Example commands ──────────────────────────
              _ExampleCommands(langCode: langProvider.langCode),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String label;
  final String text;
  final Color color;

  const _TextBubble({
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), // ✅ Fixed withValues
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)), // ✅ Fixed withValues
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ExampleCommands extends StatelessWidget {
  final String langCode;

  const _ExampleCommands({required this.langCode});

  static const Map<String, List<String>> _examples = {
    'en': [
      '"Go to Chapel of Light"',
      '"Where am I?"',
      '"Show all hostels"',
      '"Find the library"',
    ],
    'yo': [
      '"Lọ sí Chapel of Light"',
      '"Ibo ni mo wà?"',
      '"Fihàn gbogbo hostels"',
      '"Wá library"',
    ],
    'ig': [
      '"Gaa Chapel of Light"',
      '"Ebe nọ m?"',
      '"Gosi ihe nile hostel"',
      '"Chọta library"',
    ],
    'pidgin': [
      '"Take me go Chapel of Light"',
      '"Wia I dey?"',
      '"Show all hostels"',
      '"Find library"',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examples = _examples[langCode] ?? _examples['en']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try saying:',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55), // ✅ Fixed withValues
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((cmd) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(cmd, style: theme.textTheme.bodySmall),
            );
          }).toList(),
        ),
      ],
    );
  }
}
// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../presentation/providers/app_state_provider.dart';
import '../../multilingual/localization/app_localization.dart';
import '../../multilingual/providers/language_provider.dart';
import '../../navigation/services/offline_map_service.dart';
import '../../voice_assistant/providers/voice_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final OfflineMapService _offlineService = sl<OfflineMapService>();

  // ── Cache state ───────────────────────────────────────────
  double _cacheSizeMB = 0; // double — matches getCacheSizeInMB() return type
  bool _loadingCacheSize = true;
  bool _clearingCache = false;

  // ── Download state ────────────────────────────────────────
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  PreCacheResult? _lastDownloadResult;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  @override
  void dispose() {
    // Abort any in-progress download so it doesn't write to disk after
    // the screen is gone.
    if (_isDownloading) _offlineService.cancelPreCache();
    super.dispose();
  }

  // ── Cache helpers ─────────────────────────────────────────

  Future<void> _loadCacheSize() async {
    // Show "Calculating..." while the async read is in flight.
    if (mounted) setState(() => _loadingCacheSize = true);

    final size = await _offlineService.getCacheSizeInMB();

    if (mounted) {
      setState(() {
        _cacheSizeMB = size;
        _loadingCacheSize = false;
      });
    }
  }

  Future<void> _clearCache() async {
    if (!mounted) return;
    setState(() => _clearingCache = true);

    try {
      await _offlineService.clearTileCache();
    } finally {
      if (mounted) {
        setState(() => _clearingCache = false);
        Helpers.showSnackBar(context, context.t('settings_cache_cleared'));
      }
    }

    await _loadCacheSize();
  }

  // ── Download helpers ──────────────────────────────────────

  Future<void> _startDownload() async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _lastDownloadResult = null;
    });

    try {
      final result = await _offlineService.preCacheCampusTiles(
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );

      if (!mounted) return;
      _lastDownloadResult = result;

      // Surface a meaningful result — not just "done".
      final msg = result.failed == 0
          ? context.tArgs('settings_tiles_downloaded', {
        'count': '${result.downloaded}',
      })
          : context.tArgs('settings_download_partial', {
        'downloaded': '${result.downloaded}',
        'failed': '${result.failed}',
      });
      Helpers.showSnackBar(context, msg, isError: result.failed > 0);
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          context.t('settings_download_failed'),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
        await _loadCacheSize();
      }
    }
  }

  void _cancelDownload() {
    _offlineService.cancelPreCache();
    if (mounted) setState(() => _isDownloading = false);
  }

  // ── Download confirmation dialog ──────────────────────────

  void _showDownloadDialog(BuildContext screenContext) {
    // Compute tile count and localized strings from the screen context
    // before opening the dialog — avoids using the dialog's context for
    // screen-level concerns, and is safe if the screen unmounts.
    final tileCount = _offlineService.estimateTileCount();
    final title = screenContext.t('settings_download_dialog_title');
    final content = screenContext.tArgs(
      'settings_download_dialog_content',
      {'count': '$tileCount'},
    );
    final cancelLabel = screenContext.t('btn_cancel');
    final downloadLabel = screenContext.t('btn_download');

    showDialog<void>(
      context: screenContext,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(screenContext),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(screenContext);
              _startDownload();
            },
            child: Text(downloadLabel),
          ),
        ],
      ),
    );
  }

  // ── Language tile callback ────────────────────────────────

  Future<void> _onLanguageSelected(String langCode) async {
    final langProvider = context.read<LanguageProvider>();
    final appState = context.read<AppStateProvider>();
    final voice = context.read<VoiceProvider>();

    await langProvider.setLanguage(langCode);
    if (!mounted) return;

    await appState.onLanguageChanged(langCode);
    if (!mounted) return;

    await voice.setLanguage(langCode);
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final appState = context.watch<AppStateProvider>();
    final languageEntries = AppConstants.languageNames.entries.toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Language ───────────────────────────────────────
          _SectionHeader(
            title: context.t('settings_language'),
            icon: Icons.language_rounded,
          ),
          const SizedBox(height: 10),

          // Stagger each tile by its index so they animate in sequence.
          for (var i = 0; i < languageEntries.length; i++)
            _LanguageTile(
              langCode: languageEntries[i].key,
              langName: languageEntries[i].value,
              isSelected: langProvider.isSelected(languageEntries[i].key),
              onTap: () => _onLanguageSelected(languageEntries[i].key),
            ).animate(delay: (50 * i).ms).fadeIn().slideX(begin: -0.05),

          const SizedBox(height: 24),

          // ── Appearance ─────────────────────────────────────
          _SectionHeader(
            title: context.t('settings_appearance'),
            icon: Icons.palette_rounded,
          ),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              title: Text(
                context.t('settings_dark_mode'),
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                appState.isDarkMode
                    ? context.t('settings_dark_mode_on')
                    : context.t('settings_dark_mode_off'),
                style: theme.textTheme.bodySmall,
              ),
              value: appState.isDarkMode,
              activeTrackColor: AppTheme.cuNavy,
              secondary: const Icon(
                Icons.brightness_medium_rounded,
                color: AppTheme.cuNavy,
              ),
              onChanged: appState.setDarkMode,
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── Voice & Speech ─────────────────────────────────
          _SectionHeader(
            title: context.t('settings_voice_speech'),
            icon: Icons.settings_voice_rounded,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.download_for_offline_rounded,
                    color: AppTheme.cuNavy,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('settings_offline_speech'),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          context.t('settings_offline_speech_desc'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<VoiceProvider>().openOfflineSpeechSettings(),
                    child: Text(context.t('settings_open_speech_settings')),
                  ),
                ],
              ),
            ),
          ).animate(delay: 125.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── Offline Maps ───────────────────────────────────
          _SectionHeader(
            title: context.t('settings_offline_maps'),
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cache size row
                  Row(
                    children: [
                      const Icon(Icons.storage_rounded, color: AppTheme.cuNavy),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t('settings_tile_cache'),
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              _loadingCacheSize
                                  ? context.t('settings_cache_calculating')
                                  : context.tArgs('settings_cache_size', {
                                'size': _cacheSizeMB.toStringAsFixed(1),
                              }),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _clearingCache ? null : _clearCache,
                        child: _clearingCache
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(context.t('settings_clear_cache')),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Download progress or button
                  if (_isDownloading) ...[
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: AppTheme.lightBorder,
                      color: AppTheme.cuNavy,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tArgs('settings_download_progress', {
                            'percent': (_downloadProgress * 100)
                                .toStringAsFixed(0),
                          }),
                          style: theme.textTheme.bodySmall,
                        ),
                        // Cancel button — wired to cancelPreCache()
                        TextButton(
                          onPressed: _cancelDownload,
                          child: Text(context.t('btn_cancel')),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Show last result summary if available
                    if (_lastDownloadResult != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          context.tArgs('settings_last_download_summary', {
                            'downloaded': '${_lastDownloadResult!.downloaded}',
                            'failed': '${_lastDownloadResult!.failed}',
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _lastDownloadResult!.failed > 0
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDownloadDialog(context),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(context.t('settings_download_tiles')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── About ──────────────────────────────────────────
          _SectionHeader(
            title: context.t('settings_about'),
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AboutRow(
                    label: context.t('app_name'),
                    value: AppConstants.appName,
                  ),
                  const Divider(height: 16),
                  _AboutRow(
                    label: context.t('version'),
                    value: AppConstants.appVersion,
                  ),
                  const Divider(height: 16),
                  _AboutRow(
                    label: context.t('university'),
                    value: AppConstants.universityName,
                  ),
                  const Divider(height: 16),
                  _AboutRow(
                    label: context.t('campus'),
                    value: AppConstants.universityAddr,
                  ),
                ],
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: AppTheme.cuNavy, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.cuNavy,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final String langCode;
  final String langName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.langCode,
    required this.langName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.cuNavy.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              langCode.toUpperCase().substring(0, 2),
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? AppTheme.cuNavy
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(langName, style: theme.textTheme.titleMedium),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppTheme.cuNavy)
            : Icon(
          Icons.radio_button_unchecked_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ── About row ─────────────────────────────────────────────────────────────────

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
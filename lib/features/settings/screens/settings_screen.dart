// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../multilingual/providers/language_provider.dart';
import '../../multilingual/localization/app_localization.dart';
import '../../voice_assistant/providers/voice_provider.dart';
import '../../../presentation/providers/app_state_provider.dart';
import '../../navigation/services/offline_map_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final OfflineMapService _offlineService = sl<OfflineMapService>();
  int _cacheSizeMB = 0;
  bool _loadingCacheSize = true;
  bool _clearingCache = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await _offlineService.getCacheSizeInMB();
    if (mounted) {
      setState(() {
        _cacheSizeMB = size;
        _loadingCacheSize = false;
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() => _clearingCache = true);
    await _offlineService.clearTileCache();
    await _loadCacheSize();
    setState(() => _clearingCache = false);
    if (mounted) Helpers.showSnackBar(context, context.t('settings_cache_cleared'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final appState = context.watch<AppStateProvider>();
    final voiceProvider = context.watch<VoiceProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Language ───────────────────────────────────────
          _SectionHeader(title: context.t('settings_language'), icon: Icons.language_rounded),
          const SizedBox(height: 10),
          ...AppConstants.languageNames.entries.map((entry) {
            return _LanguageTile(
              langCode: entry.key,
              langName: entry.value,
              isSelected: langProvider.isSelected(entry.key),
              onTap: () async {
                final appState = context.read<AppStateProvider>();
                final voice = context.read<VoiceProvider>();
                
                await langProvider.setLanguage(entry.key);
                await appState.onLanguageChanged(entry.key);
                await voice.setLanguage(entry.key);
              },
            ).animate(delay: 50.ms).fadeIn().slideX(begin: -0.05);
          }),

          const SizedBox(height: 24),

          // ── Appearance ─────────────────────────────────────
          _SectionHeader(title: context.t('settings_appearance'), icon: Icons.palette_rounded),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              title: Text(context.t('settings_dark_mode'), style: theme.textTheme.titleMedium),
              subtitle: Text(
                appState.isDarkMode ? context.t('settings_dark_mode_on') : context.t('settings_dark_mode_off'),
                style: theme.textTheme.bodySmall,
              ),
              value: appState.isDarkMode,
              activeTrackColor: AppTheme.cuNavy, // ✅ Swapped activeColor to activeTrackColor for M3 Switch constraints
              secondary: const Icon(
                Icons.brightness_medium_rounded, // ✅ Uses generic const Icon
                color: AppTheme.cuNavy,
              ),
              onChanged: (val) => appState.setDarkMode(val),
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── Offline Maps ───────────────────────────────────
          _SectionHeader(title: context.t('settings_offline_maps'), icon: Icons.map_outlined),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage_rounded,
                          color: AppTheme.cuNavy), // ✅ Swapped primaryColor to cuNavy
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t('settings_tile_cache'),
                                style: theme.textTheme.titleMedium),
                            Text(
                              _loadingCacheSize
                                  ? context.t('settings_cache_calculating')
                                  : context.tArgs('settings_cache_size', {'size': '$_cacheSizeMB'}),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _clearingCache ? null : _clearCache,
                        child: _clearingCache
                            ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(context.t('settings_clear_cache')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_isDownloading) ...[
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: AppTheme.lightBorder,
                      color: AppTheme.cuNavy,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tArgs(
                        'settings_download_progress',
                        {'percent': (_downloadProgress * 100).toStringAsFixed(0)},
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDownloadDialog(context),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(context.t('settings_download_tiles')),
                      ),
                    ),
                ],
              ),
            ),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── About ──────────────────────────────────────────
          _SectionHeader(title: context.t('settings_about'), icon: Icons.info_outline_rounded),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AboutRow(label: context.t('app_name'),   value: AppConstants.appName),
                  const Divider(height: 16),
                  _AboutRow(label: context.t('version'),    value: AppConstants.appVersion),
                  const Divider(height: 16),
                  _AboutRow(label: context.t('university'), value: AppConstants.universityName),
                  const Divider(height: 16),
                  _AboutRow(label: context.t('campus'),     value: AppConstants.universityAddr), // ✅ Swapped universityAddress to universityAddr
                ],
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });
    try {
      await _offlineService.preCacheCampusTiles(
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (mounted) Helpers.showSnackBar(context, context.t('settings_tiles_downloaded'));
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, context.t('settings_download_failed'),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
      await _loadCacheSize();
    }
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('settings_download_dialog_title')),
        content: Text(context.t('settings_download_dialog_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('btn_cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownload();
            },
            child: Text(context.t('btn_download')),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon}); // ✅ Standard constructor keeps const usability

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: AppTheme.cuNavy, size: 18), // ✅ Swapped primaryColor to cuNavy
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.cuNavy, // ✅ Swapped primaryColor to cuNavy
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

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
                ? AppTheme.cuNavy.withValues(alpha: 0.1) // ✅ Swapped to cuNavy + withValues
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              langCode.toUpperCase().substring(0, 2),
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? AppTheme.cuNavy // ✅ Swapped primaryColor to cuNavy
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(langName, style: theme.textTheme.titleMedium),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded,
            color: AppTheme.cuNavy) // ✅ Swapped primaryColor to cuNavy
            : Icon(Icons.radio_button_unchecked_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3)), // ✅ Swapped withValues
      ),
    );
  }
}

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
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55), // ✅ Swapped withValues
            )),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

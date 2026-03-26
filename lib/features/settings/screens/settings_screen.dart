// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../multilingual/providers/language_provider.dart';
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
    if (mounted) Helpers.showSnackBar(context, 'Map cache cleared');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Language ───────────────────────────────────────
          const _SectionHeader(title: 'Language', icon: Icons.language_rounded), // ✅ Added const
          const SizedBox(height: 10),
          ...AppConstants.languageNames.entries.map((entry) {
            return _LanguageTile(
              langCode: entry.key,
              langName: entry.value,
              isSelected: langProvider.isSelected(entry.key),
              onTap: () async {
                await langProvider.setLanguage(entry.key);
                await context.read<AppStateProvider>()
                    .onLanguageChanged(entry.key);
              },
            ).animate(delay: 50.ms).fadeIn().slideX(begin: -0.05);
          }),

          const SizedBox(height: 24),

          // ── Appearance ─────────────────────────────────────
          const _SectionHeader(title: 'Appearance', icon: Icons.palette_rounded), // ✅ Added const
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              title: Text('Dark Mode', style: theme.textTheme.titleMedium),
              subtitle: Text(
                appState.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
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
          const _SectionHeader(title: 'Offline Maps', icon: Icons.map_outlined), // ✅ Added const
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
                            Text('Tile Cache',
                                style: theme.textTheme.titleMedium),
                            Text(
                              _loadingCacheSize
                                  ? 'Calculating...'
                                  : '$_cacheSizeMB MB used',
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
                            : const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDownloadDialog(context),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download Campus Tiles'),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── About ──────────────────────────────────────────
          const _SectionHeader(title: 'About', icon: Icons.info_outline_rounded), // ✅ Added const
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AboutRow(label: 'App Name',   value: AppConstants.appName),
                  const Divider(height: 16),
                  _AboutRow(label: 'Version',    value: AppConstants.appVersion),
                  const Divider(height: 16),
                  _AboutRow(label: 'University', value: AppConstants.universityName),
                  const Divider(height: 16),
                  _AboutRow(label: 'Campus',     value: AppConstants.universityAddr), // ✅ Swapped universityAddress to universityAddr
                ],
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog<void>( // ✅ Strictly typed
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Download Offline Map'),
        content: const Text(
            'This will download map tiles for the Covenant University campus for offline use. Requires internet and uses approximately 20–50 MB.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'Downloading map tiles...');
            },
            child: const Text('Download'),
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
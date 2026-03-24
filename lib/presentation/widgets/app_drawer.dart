// lib/presentation/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/multilingual/providers/language_provider.dart';
import '../../presentation/providers/app_state_provider.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final appState = context.watch<AppStateProvider>();

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            _DrawerHeader(),

            const SizedBox(height: 8),

            // ── Navigation Items ─────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.map_rounded,
                    label: 'Campus Map',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.map, (_) => false,
                      );
                    },
                  ).animate(delay: 50.ms).fadeIn().slideX(begin: -0.1),

                  _DrawerItem(
                    icon: Icons.mic_rounded,
                    label: 'Voice Assistant',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.voice);
                    },
                  ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1),

                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Campus Information',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.info);
                    },
                  ).animate(delay: 150.ms).fadeIn().slideX(begin: -0.1),

                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),

                  const Divider(height: 24),

                  // Language quick-switch
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    child: Text(
                      'Language',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  ...AppConstants.languageNames.entries.map((entry) {
                    final isSelected = langProvider.isSelected(entry.key);
                    return ListTile(
                      dense: true,
                      onTap: () => langProvider.setLanguage(entry.key),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            entry.key.substring(0, 2).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(entry.value, style: theme.textTheme.bodyMedium),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                          color: AppTheme.primaryColor, size: 18)
                          : null,
                    );
                  }),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppConstants.appName} v${AppConstants.appVersion}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  // Dark mode toggle
                  GestureDetector(
                    onTap: () => appState.setDarkMode(!appState.isDarkMode),
                    child: Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: appState.isDarkMode
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: appState.isDarkMode
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            appState.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            size: 12,
                            color: appState.isDarkMode
                                ? AppTheme.primaryColor
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer Header ─────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF2D5FA6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppConstants.appName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppConstants.universityName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            AppConstants.universityAddress,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer List Item ──────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(label, style: theme.textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
    );
  }
}
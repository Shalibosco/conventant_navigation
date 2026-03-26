// lib/features/navigation/widgets/destination_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/navigation_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_theme.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final destination = navProvider.selectedDestination;
    final theme = Theme.of(context);

    if (destination == null) return const SizedBox.shrink();

    final color = Helpers.getCategoryColor(destination.category);
    final distance = Helpers.formatDistance(navProvider.distanceToDestination);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14), // ✅ Fixed withValues
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12), // ✅ Fixed withValues
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Helpers.getCategoryIcon(destination.category),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        Helpers.capitalize(destination.category),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55), // ✅ Fixed withValues
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: navProvider.cancelNavigation,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.08), // ✅ Fixed withValues
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Stats ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: distance,
                  color: AppTheme.cuNavy, // ✅ Fixed: Pointing to cuNavy
                ),
                Container(width: 1, height: 36, color: theme.dividerColor),
                _StatItem(
                  icon: Icons.directions_walk_rounded,
                  label: 'Walk Time',
                  value: navProvider.estimatedTime,
                  color: AppTheme.navGreen, // ✅ Fixed: Pointing to navGreen
                ),
                Container(width: 1, height: 36, color: theme.dividerColor),
                _StatItem(
                  icon: Icons.route_rounded,
                  label: 'Route',
                  value: navProvider.hasRoute ? 'Ready' : 'Loading...',
                  color: AppTheme.cuGold, // ✅ Fixed: Pointing to cuGold
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Navigation active banner ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.cuNavy, // ✅ Swapped to Navy gradient for aesthetics
                    AppTheme.cuNavy.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Navigation Active — Follow the Route',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: color, fontSize: 13)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}
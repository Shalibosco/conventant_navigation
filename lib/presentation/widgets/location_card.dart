// lib/presentation/widgets/location_card.dart

import 'package:flutter/material.dart';
import '../../data/models/location_model.dart'; // ✅ Removed unused flutter_animate import
import '../../core/utils/helpers.dart';
import '../../core/theme/app_theme.dart';

class LocationCard extends StatelessWidget {
  final LocationModel location;
  final String langCode;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;
  final double? distanceMeters;
  final bool isSelected;

  const LocationCard({
    super.key,
    required this.location,
    required this.langCode,
    this.onTap,
    this.onNavigate,
    this.distanceMeters,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Helpers.getCategoryColor(location.category);
    final name = location.getLocalizedName(langCode);
    final description = location.getLocalizedDescription(langCode);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08) // ✅ Swapped withValues
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07), // ✅ Swapped withValues
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Category Icon ─────────────────────────
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), // ✅ Swapped withValues
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Helpers.getCategoryIcon(location.category),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // ── Info ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55), // ✅ Swapped withValues
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (distanceMeters != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_walk_rounded,
                            size: 13,
                            color: AppTheme.navGreen, // ✅ Mapped to navGreen
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${Helpers.formatDistance(distanceMeters!)} · '
                                '${Helpers.estimateWalkTime(distanceMeters!)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.navGreen, // ✅ Mapped to navGreen
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Navigate Button ───────────────────────
              if (onNavigate != null)
                GestureDetector(
                  onTap: onNavigate,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.cuNavy, // ✅ Mapped to cuNavy
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
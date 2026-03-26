// lib/features/information/widgets/info_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/info_model.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_theme.dart';

class InfoCard extends StatelessWidget {
  final InfoModel item;
  final String langCode;

  const InfoCard({super.key, required this.item, required this.langCode});

  IconData _getIcon() {
    switch (item.iconName) {
      case 'church':   return Icons.church_rounded;
      case 'medical':  return Icons.local_hospital_rounded;
      case 'admin':    return Icons.business_rounded;
      case 'academic': return Icons.school_rounded;
      case 'rule':     return Icons.gavel_rounded;
      default:         return Icons.info_outline_rounded;
    }
  }

  Color _getCategoryColor() {
    switch (item.category) {
      case 'rule':     return const Color(0xFFE53935); // Matches your AppTheme.errorRed
      case 'facility': return AppTheme.cuNavy; // ✅ Fixed: Using cuNavy
      case 'contact':  return AppTheme.navGreen; // ✅ Reused your AppTheme.navGreen
      case 'event':    return AppTheme.cuGold; // ✅ Fixed: Using cuGold
      default:         return AppTheme.cuNavy; // ✅ Fixed
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getCategoryColor();
    final title = item.getLocalizedTitle(langCode);
    final content = item.getLocalizedContent(langCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              // ✅ Fixed: withValues instead of withOpacity
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIcon(), color: color, size: 22),
          ),
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    // ✅ Fixed: withValues instead of withOpacity
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    Helpers.capitalize(item.category),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(content, style: theme.textTheme.bodyMedium),
            if (item.lastUpdated != null) ...[
              const SizedBox(height: 10),
              Text(
                'Last updated: ${item.lastUpdated}',
                style: theme.textTheme.labelSmall?.copyWith(
                  // ✅ Fixed: withValues instead of withOpacity
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
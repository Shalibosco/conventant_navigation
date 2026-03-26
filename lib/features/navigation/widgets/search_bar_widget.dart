// lib/features/navigation/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../../../core/utils/helpers.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({super.key});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, NavigationProvider provider) {
    provider.search(query);
    setState(() => _isExpanded = query.isNotEmpty);
  }

  void _clear(NavigationProvider provider) {
    _controller.clear();
    provider.search('');
    _focusNode.unfocus();
    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navProvider = context.watch<NavigationProvider>();

    return Column(
      children: [
        // ── Search Input ────────────────────────────────────
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded,
                  color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (v) => _onSearchChanged(v, navProvider),
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search buildings, hostels, offices...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () => _clear(navProvider),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.close_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20),
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // ── Search Results Dropdown ─────────────────────────
        if (_isExpanded && navProvider.searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navProvider.searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final loc = navProvider.searchResults[index];
                return ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Helpers.getCategoryColor(loc.category)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Helpers.getCategoryIcon(loc.category),
                      color: Helpers.getCategoryColor(loc.category),
                      size: 20,
                    ),
                  ),
                  title: Text(loc.name, style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    Helpers.capitalize(loc.category),
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    _clear(navProvider);
                    navProvider.navigateTo(loc);
                  },
                );
              },
            ),
          ),

        // ── Category Filter Chips ───────────────────────────
        if (!_isExpanded) ...[
          const SizedBox(height: 10),
          _CategoryFilterRow(),
        ],
      ],
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final List<Map<String, dynamic>> _filters = const [
    {'label': 'All',     'value': 'all',      'icon': Icons.grid_view_rounded},
    {'label': 'Academic','value': 'academic', 'icon': Icons.school_rounded},
    {'label': 'Hostel',  'value': 'hostel',   'icon': Icons.bed_rounded},
    {'label': 'Food',    'value': 'food',     'icon': Icons.restaurant_rounded},
    {'label': 'Worship', 'value': 'worship',  'icon': Icons.church_rounded},
    {'label': 'Sports',  'value': 'sports',   'icon': Icons.sports_soccer_rounded},
    {'label': 'Admin',   'value': 'admin',    'icon': Icons.business_rounded},
    {'label': 'Medical', 'value': 'medical',  'icon': Icons.local_hospital_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = navProvider.activeFilter == filter['value'];

          return GestureDetector(
            onTap: () =>
                navProvider.filterByCategory(filter['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 14,
                    color: isActive
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    filter['label'] as String,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

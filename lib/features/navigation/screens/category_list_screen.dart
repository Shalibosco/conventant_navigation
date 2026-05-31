// lib/features/navigation/screens/category_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';

import '../providers/navigation_provider.dart';
import '../../multilingual/localization/app_localization.dart';
import '../../multilingual/providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/location_model.dart';

class CategoryListScreen extends StatefulWidget {
  final String category;
  final String categoryLabel;

  const CategoryListScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late List<LocationModel> categoryLocations;

  @override
  void initState() {
    super.initState();
    _loadCategoryLocations();
  }

  void _loadCategoryLocations() {
    final nav = context.read<NavigationProvider>();
    // Get all locations and filter by category
    categoryLocations = nav.searchResults.isEmpty
        ? <LocationModel>[] // If no results, show empty for now
        : nav.searchResults;

    // If no filtered results, load from all locations (fallback)
    if (categoryLocations.isEmpty) {
      // We need to filter from all locations - this is a limitation
      // For now we'll work with what we have
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final langCode = context.watch<LanguageProvider>().langCode;
    final theme = Theme.of(context);

    // Get locations for this category
    final locations = nav.searchResults.isNotEmpty
        ? nav.searchResults
        : <LocationModel>[];

    final categoryColor = Helpers.getCategoryColor(widget.category);
    final categoryIcon = Helpers.getCategoryIcon(widget.category);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          // Reset filters when going back
          nav.filterByCategory('all');
          nav.search('');
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────
            SliverAppBar(
              elevation: 0,
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
              expandedHeight: 140,
              floating: true,
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.categoryLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor,
                        categoryColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcon,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content Count ──────────────────────────────────
            if (locations.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    context.tArgs('search_results_count', {
                      'count': '${locations.length}',
                    }),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightSubText,
                    ),
                  ),
                ),
              ),

            // ── Location List ──────────────────────────────────
            if (locations.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_off_rounded,
                          size: 40,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t('no_results'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t('no_results_subtitle'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightSubText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final location = locations[index];
                  return _LocationTile(
                    location: location,
                    langCode: langCode,
                    categoryColor: categoryColor,
                    onNavigate: () => _navigateTo(location),
                    index: index,
                  );
                }, childCount: locations.length),
              ),

            // ── Bottom padding ─────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  void _navigateTo(LocationModel location) {
    final nav = context.read<NavigationProvider>();
    nav.filterByCategory('all');
    nav.search('');
    nav.navigateTo(location);

    // Pop this screen and return to map
    Navigator.pop(context);
  }
}

// ── Individual Location Tile ───────────────────────────────────
class _LocationTile extends StatelessWidget {
  final LocationModel location;
  final String langCode;
  final Color categoryColor;
  final VoidCallback onNavigate;
  final int index;

  const _LocationTile({
    required this.location,
    required this.langCode,
    required this.categoryColor,
    required this.onNavigate,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final theme = Theme.of(context);
    final userLocation = nav.userLocation;

    // Calculate distance if user location is available
    String distanceText = context.t('distance_unknown');
    if (userLocation != null) {
      final destLatLng = LatLng(location.latitude, location.longitude);
      const Distance distance = Distance();
      final meters = distance.as(LengthUnit.Meter, userLocation, destLatLng);
      distanceText = Helpers.formatDistance(meters);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GestureDetector(
        onTap: onNavigate,
        child:
            Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // ── Category Badge ────────────────────────────
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Helpers.getCategoryIcon(location.category),
                            color: categoryColor,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ── Location Info ─────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                location.getLocalizedName(langCode),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.straighten_rounded,
                                    size: 14,
                                    color: AppTheme.lightSubText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    distanceText,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.lightSubText,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    height: 12,
                                    color: AppTheme.lightBorder,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      location.getLocalizedDescription(
                                        langCode,
                                      ),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: AppTheme.lightSubText,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ── Navigation Arrow ──────────────────────────
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: categoryColor,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate(delay: (index * 50).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: -0.1, duration: 300.ms),
      ),
    );
  }
}

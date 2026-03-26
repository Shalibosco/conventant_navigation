// lib/features/navigation/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../providers/navigation_provider.dart';
import '../../voice_assistant/providers/voice_provider.dart';
import '../../voice_assistant/services/voice_command_handler.dart';
import '../../multilingual/providers/language_provider.dart';
import '../../../presentation/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/location_model.dart';
import '../../information/screens/info_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../voice_assistant/widgets/voice_fab.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final PanelController _panelController = PanelController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _searchExpanded = false;

  // 📍 Covenant University Default Center
  static const LatLng _initialCamera = LatLng(6.6726, 3.1616);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final nav = context.read<NavigationProvider>();
    final voice = context.read<VoiceProvider>();
    final lang = context.read<LanguageProvider>();

    await nav.initialize();
    await voice.initialize(lang.langCode);

    voice.onCommandResolved = _handleVoiceCommand;
    nav.startLocationTracking();
  }

  void _handleVoiceCommand(VoiceCommand cmd) {
    final nav = context.read<NavigationProvider>();
    switch (cmd.type) {
      case VoiceCommandType.navigate:
        if (cmd.resolvedLocation != null) {
          nav.navigateTo(cmd.resolvedLocation!);
          _flyTo(LatLng(cmd.resolvedLocation!.latitude, cmd.resolvedLocation!.longitude));
          _panelController.open();
        }
        break;
      case VoiceCommandType.whereAmI:
        if (nav.userLocation != null) _flyTo(nav.userLocation!);
        break;
      case VoiceCommandType.listCategory:
        if (cmd.category != null) nav.filterByCategory(cmd.category!);
        break;
      case VoiceCommandType.search:
        if (cmd.query != null) {
          _searchController.text = cmd.query!;
          nav.search(cmd.query!);
          setState(() => _searchExpanded = true);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _flyTo(LatLng target, {double zoom = 16.5}) async {
    _mapController.move(target, zoom);
  }

  Future<void> _recenter() async {
    final nav = context.read<NavigationProvider>();
    if (nav.userLocation != null) {
      _flyTo(nav.userLocation!);
    } else {
      Helpers.showSnackBar(context, 'Getting your location...');
      await nav.fetchUserLocation();
      if (nav.userLocation != null) _flyTo(nav.userLocation!);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final isDark = context.watch<AppStateProvider>().isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: nav.isNavigating ? 160 : 0,
        maxHeight: 340,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
        panel: nav.isNavigating
            ? _NavigationPanel(
          onClose: () {
            nav.cancelNavigation();
            _panelController.close();
          },
        )
            : const SizedBox.shrink(),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCamera,
                initialZoom: 16.5,
                maxZoom: 18.0,
                minZoom: 14.0,
                onTap: (_, __) {
                  _searchFocus.unfocus();
                  setState(() => _searchExpanded = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: isDark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.covenant.campus_navigation',
                ),
                PolylineLayer(
                  polylines: nav.osmPolylines,
                ),
                MarkerLayer(
                  markers: nav.osmMarkers,
                ),
              ],
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _TopButton(
                            icon: Icons.menu_rounded,
                            onTap: () => Scaffold.of(context).openDrawer(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _SearchBar(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                onChanged: (q) {
                                  nav.search(q);
                                  setState(() => _searchExpanded = q.isNotEmpty);
                                },
                                onClear: () {
                                  _searchController.clear();
                                  nav.search('');
                                  setState(() => _searchExpanded = false);
                                },
                              )),
                          const SizedBox(width: 10),
                          _TopButton(
                            icon: Icons.info_outline_rounded,
                            onTap: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const InfoScreen())),
                          ),
                        ],
                      ),
                      if (_searchExpanded && nav.searchResults.isNotEmpty)
                        _SearchResults(
                          results: nav.searchResults,
                          onSelect: (loc) {
                            _searchController.clear();
                            nav.search('');
                            setState(() => _searchExpanded = false);
                            _searchFocus.unfocus();
                            nav.navigateTo(loc);
                            _flyTo(LatLng(loc.latitude, loc.longitude));
                            _panelController.open();
                          },
                        ),
                      if (!_searchExpanded) ...[
                        const SizedBox(height: 10),
                        const _CategoryChips(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              right: 16,
              bottom: nav.isNavigating ? 200 : 120,
              child: Column(
                children: [
                  _MapFab(icon: Icons.my_location_rounded, onTap: _recenter),
                  const SizedBox(height: 12),
                  _MapFab(
                    icon: Icons.settings_rounded,
                    onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: nav.isNavigating ? 180 : 40,
              left: 0,
              right: 0,
              child: const Center(child: VoiceFab()),
            ),

            if (!context.watch<AppStateProvider>().isOnline)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: const _OfflineBanner(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: AppTheme.cuNavy, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search campus locations...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.lightSubText),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.close_rounded,
                      color: AppTheme.lightSubText, size: 20)),
            ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<LocationModel> results;
  final ValueChanged<LocationModel> onSelect;

  const _SearchResults({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
        itemBuilder: (_, i) {
          final loc = results[i];
          final color = Helpers.getCategoryColor(loc.category);
          return ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Helpers.getCategoryIcon(loc.category),
                  color: color, size: 20),
            ),
            title: Text(loc.name, style: theme.textTheme.titleMedium),
            subtitle: Text(Helpers.capitalize(loc.category),
                style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => onSelect(loc),
          );
        },
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  final List<Map<String, dynamic>> _filters = const [
    {'label': 'All', 'value': 'all', 'icon': Icons.grid_view_rounded},
    {'label': 'Academic', 'value': 'academic', 'icon': Icons.school_rounded},
    {'label': 'Hostel', 'value': 'hostel', 'icon': Icons.bed_rounded},
    {'label': 'Food', 'value': 'food', 'icon': Icons.restaurant_rounded},
    {'label': 'Worship', 'value': 'worship', 'icon': Icons.church_rounded},
    {'label': 'Sports', 'value': 'sports', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Admin', 'value': 'admin', 'icon': Icons.business_rounded},
    {'label': 'Medical', 'value': 'medical', 'icon': Icons.local_hospital_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final active = nav.activeFilter == f['value'];
          return GestureDetector(
            onTap: () => nav.filterByCategory(f['value'] as String),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppTheme.cuNavy : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(children: [
                Icon(f['icon'] as IconData,
                    size: 14,
                    color: active ? Colors.white : AppTheme.lightSubText),
                const SizedBox(width: 5),
                Text(f['label'] as String,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color:
                        active ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  final VoidCallback onClose;

  const _NavigationPanel({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final dest = nav.selectedDestination;
    final theme = Theme.of(context);
    if (dest == null) return const SizedBox.shrink();
    final color = Helpers.getCategoryColor(dest.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(Helpers.getCategoryIcon(dest.category),
                      color: color, size: 26)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dest.name,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(Helpers.capitalize(dest.category),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.lightSubText)),
                    ],
                  )),
              GestureDetector(
                  onTap: onClose,
                  child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                          color: AppTheme.lightBorder, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 18))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cuNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cuNavy.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                    icon: Icons.straighten_rounded,
                    label: 'Distance',
                    value: Helpers.formatDistance(nav.distanceToDestination),
                    color: AppTheme.cuNavy),
                Container(width: 1, height: 36, color: AppTheme.lightBorder),
                _Stat(
                    icon: Icons.directions_walk_rounded,
                    label: 'Walk Time',
                    value: nav.estimatedTime,
                    color: AppTheme.navGreen),
                Container(width: 1, height: 36, color: AppTheme.lightBorder),
                _Stat(
                    icon: Icons.route_rounded,
                    label: 'Route',
                    value: nav.hasRoute ? 'Ready' : '...',
                    color: AppTheme.cuGold),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('End Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: t.textTheme.titleMedium?.copyWith(color: color, fontSize: 13)),
      Text(label, style: t.textTheme.labelSmall?.copyWith(fontSize: 10)),
    ]);
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: AppTheme.cuNavy, size: 24),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, color: AppTheme.cuNavy, size: 22),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: AppTheme.warningAmber,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('Offline mode',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

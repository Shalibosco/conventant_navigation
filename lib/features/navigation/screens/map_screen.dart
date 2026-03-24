// lib/features/navigation/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/map_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/destination_card.dart';
import '../../voice_assistant/widgets/voice_ui.dart';
import '../../voice_assistant/providers/voice_provider.dart';
import '../../voice_assistant/services/voice_command_handler.dart';
import '../../multilingual/providers/language_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProviders();
    });
  }

  Future<void> _initProviders() async {
    final navProvider = context.read<NavigationProvider>();
    final langProvider = context.read<LanguageProvider>();
    final voiceProvider = context.read<VoiceProvider>();

    await navProvider.initialize();
    await voiceProvider.initialize(langProvider.langCode);

    // Connect voice commands to navigation
    voiceProvider.onCommandResolved = (VoiceCommand command) {
      _handleVoiceCommand(command);
    };

    navProvider.startLocationTracking();
  }

  void _handleVoiceCommand(VoiceCommand command) {
    final navProvider = context.read<NavigationProvider>();
    final isOnline = true; // Could check NetworkService

    switch (command.type) {
      case VoiceCommandType.navigate:
        if (command.resolvedLocation != null) {
          navProvider.navigateTo(command.resolvedLocation!, isOnline: isOnline);
          _flyTo(LatLng(
            command.resolvedLocation!.latitude,
            command.resolvedLocation!.longitude,
          ));
        }
        break;

      case VoiceCommandType.whereAmI:
        if (navProvider.userLocation != null) {
          _flyTo(navProvider.userLocation!);
        }
        break;

      case VoiceCommandType.listCategory:
        if (command.category != null) {
          navProvider.filterByCategory(command.category!);
        }
        break;

      case VoiceCommandType.search:
        if (command.query != null) {
          navProvider.search(command.query!);
        }
        break;

      default:
        break;
    }
  }

  void _flyTo(LatLng target, {double zoom = AppConstants.defaultZoom}) {
    _mapController.move(target, zoom);
  }

  void _recenterOnUser() {
    final userLoc = context.read<NavigationProvider>().userLocation;
    if (userLoc != null) {
      _flyTo(userLoc);
    } else {
      Helpers.showSnackBar(context, 'Location not available yet');
    }
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navProvider = context.watch<NavigationProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP (full screen) ───────────────────────────
          Positioned.fill(
            child: MapWidget(mapController: _mapController),
          ),

          // ── TOP AREA ────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Expanded(
                      child: const MapSearchBar(),
                    ),
                    const SizedBox(width: 10),

                    // Info Button (top right)
                    _TopIconButton(
                      icon: Icons.info_outline_rounded,
                      tooltip: 'Campus Info',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.info),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── RIGHT SIDE FABs ──────────────────────────────
          Positioned(
            right: 16,
            bottom: navProvider.isNavigating ? 240 : 140,
            child: Column(
              children: [
                // Recenter
                _MapFab(
                  icon: Icons.gps_fixed_rounded,
                  onTap: _recenterOnUser,
                  tooltip: 'My Location',
                ),
                const SizedBox(height: 10),
                // Settings
                _MapFab(
                  icon: Icons.settings_rounded,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),

          // ── BOTTOM: Destination Card or Voice UI ─────────
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (navProvider.isNavigating) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const DestinationCard(),
                  ),
                  const SizedBox(height: 12),
                ],
                // Voice Assistant Button
                const VoiceUI(),
              ],
            ),
          ),

          // ── Loading Overlay ───────────────────────────────
          if (navProvider.state == NavigationState.loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reusable top icon button ───────────────────────────────
class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 24),
        ),
      ),
    );
  }
}

// ── Map FAB ────────────────────────────────────────────────
class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _MapFab({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
      ),
    );
  }
}
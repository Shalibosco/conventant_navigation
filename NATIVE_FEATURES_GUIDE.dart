// IMPLEMENTATION GUIDE: Native Phone Features & Map Tracing
// ========================================================

/// FEATURES IMPLEMENTED:
/// 1. NATIVE MICROPHONE (Speech Recognition)
/// 2. NATIVE SPEAKER (Text-to-Speech)
/// 3. MAP TRACING (User movement trail visualization)

/// ==============================================================
/// 1️⃣  NATIVE MICROPHONE - SPEECH RECOGNITION
/// ==============================================================
/*
Location: lib/features/voice_assistant/services/speech_service.dart
Provider: lib/features/voice_assistant/providers/voice_provider.dart

WHAT IT DOES:
- Listens to user's voice commands
- Recognizes spoken text in multiple languages
- Supports: English, Yoruba, Igbo, Pidgin English
- Shows partial results while listening
- Times out after configurable duration

HOW IT WORKS:
1. User taps the Voice FAB (blue microphone button)
2. App requests microphone permission
3. Speech recognition starts listening
4. User speaks a command (e.g., "Navigate to Library")
5. App recognizes the text and processes the command
6. Voice commands are routed to VoiceCommandHandler

VOICE COMMANDS SUPPORTED:
- "Navigate to [Location Name]" → Starts navigation
- "Where am I?" → Shows current location
- "Show [Category]" → Filters by category (Academic, Hostel, Food, etc.)
- "Search [Location]" → Searches for locations

PERMISSIONS REQUIRED:
Android:
  - android.permission.RECORD_AUDIO (added to AndroidManifest.xml)
iOS:
  - NSMicrophoneUsageDescription (added to Info.plist)

TESTING:
- Tap the Voice FAB on the map screen
- Say a navigation command
- Check the map for the response
*/

/// ==============================================================
/// 2️⃣  NATIVE SPEAKER - TEXT-TO-SPEECH
/// ==============================================================
/*
Location: lib/features/voice_assistant/services/text_to_speech_service.dart
Provider: lib/features/voice_assistant/providers/voice_provider.dart

WHAT IT DOES:
- Converts text to natural-sounding speech
- Uses device's native TTS engine
- Supports multiple languages
- Automatic speaker output (uses phone speaker)
- Configurable speech rate, volume, and pitch

HOW IT WORKS:
1. App calls speak(text) method
2. TTS service initializes native speaker
3. Text is converted to speech
4. Audio plays through device speaker
5. App tracks speaking state

SUPPORTED LANGUAGES:
- English (en-NG - Nigerian English)
- Yoruba (yo-NG)
- Igbo (ig-NG)
- Pidgin English (en-NG variant)

USAGE EXAMPLES IN APP:
- Welcoming user: "Welcome to Covenant University Campus Navigation"
- Navigation start: "Navigating to Library. Follow the route on the map."
- Arrival announcement: "You have arrived at the Library."
- Proximity alerts: "You're getting close to your destination"

SPEECH SETTINGS (configured in TextToSpeechService):
- Speech Rate: 0.48 (48% speed - natural pace)
- Volume: 1.0 (100%)
- Pitch: 1.05 (slightly warm tone)

PERMISSIONS REQUIRED:
Android:
  - android.permission.MODIFY_AUDIO_SETTINGS (added to AndroidManifest.xml)
iOS:
  - AVFoundation automatically handles speaker access

TESTING:
- Open Settings and enable voice announcements
- Start navigation to any location
- Listen for navigation instructions
- Hear arrival announcement when destination is reached
*/

/// ==============================================================
/// 3️⃣  MAP TRACING - USER MOVEMENT TRAIL
/// ==============================================================
/*
Location: lib/features/navigation/services/map_trail_service.dart
Provider: lib/features/navigation/providers/navigation_provider.dart
UI: lib/features/navigation/widgets/map_widget.dart

WHAT IT DOES:
- Tracks user's movement path on the map during navigation
- Displays as a light blue "breadcrumb trail"
- Updates in real-time as user walks
- Helps visualize the actual path taken vs planned route

HOW IT WORKS:
1. When user starts navigation (taps a destination)
2. MapTrailService initializes with current location
3. Location updates trigger trail point additions
4. Points spaced more than 1 meter apart are added (prevents clustering)
5. Trail is rendered as a polyline on the map overlay
6. Maximum 500 points stored to prevent memory issues

FEATURES:
- Smart point filtering: Only adds points 1+ meter apart
- Memory efficient: Removes oldest points when max reached
- Color coded: Light blue (#4A90E2) for trail vs Maroon for route
- Always visible: Shows entire journey from start to current position
- Auto-clears: Resets when new navigation starts or navigation ends
- Distance calculation: Can calculate total distance traveled

TRAIL VISUALIZATION:
- Route line (thick maroon): Planned path from you to destination
- Trail line (light blue): Actual path you've walked
- User marker (blue): Your current position
- Destination marker (red): Your target location

TECHNICAL DETAILS:
- Uses Haversine formula for accurate distance calculation
- Updates only when navigating (_isNavigating == true)
- Limited to last 500 location points (configurable)
- Minimum distance filter: 1 meter between points

USAGE IN APP:
1. Open map screen
2. Select a destination to navigate to
3. Start walking/moving
4. Blue trail appears showing your path
5. Compare your actual path with the planned route
6. At arrival, trail clears automatically

ACCESSING TRAIL DATA:
- trailService.trailPoints → List<LatLng> of all points
- trailService.hasTrail → bool if trail has points
- trailService.getTotalTrailDistance() → double (km)
- trailService.clearTrail() → Clear trail manually
- trailService.resetTrail(LatLng start) → Start new trail

TESTING:
- Start navigation to any location
- Move around the campus
- Observe the blue trail following your movement
- Compare with the maroon route line
- End navigation to see trail clear
*/

/// ==============================================================
/// INTEGRATION POINTS
/// ==============================================================
/*
1. MapScreen (lib/features/navigation/screens/map_screen.dart):
   - Displays map with trails and routes
   - Handles voice commands
   - Shows navigation panels with distance/time

2. NavigationProvider (lib/features/navigation/providers/navigation_provider.dart):
   - Manages trail service
   - Tracks location updates
   - Updates osmPolylines with trail

3. VoiceProvider (lib/features/voice_assistant/providers/voice_provider.dart):
   - Initializes TTS and STT services
   - Handles voice commands
   - Speaks navigation instructions

4. LocationService (lib/features/navigation/services/location_service.dart):
   - Provides real-time location updates
   - Used by MapTrailService for trail points
   - Updates every 3 meters (configurable)
*/

/// ==============================================================
/// PERMISSIONS SUMMARY
/// ==============================================================
/*
ANDROID (AndroidManifest.xml):
✅ android.permission.RECORD_AUDIO - Microphone recording
✅ android.permission.MODIFY_AUDIO_SETTINGS - Speaker control
✅ android.permission.ACCESS_FINE_LOCATION - Precise location
✅ android.permission.ACCESS_COARSE_LOCATION - Approximate location
✅ android.permission.ACCESS_BACKGROUND_LOCATION - Background tracking
✅ android.permission.INTERNET - Map tiles
✅ android.permission.ACCESS_NETWORK_STATE - Network status

iOS (Info.plist):
✅ NSMicrophoneUsageDescription - Microphone access
✅ NSSpeechRecognitionUsageDescription - Speech recognition
✅ NSLocationWhenInUseUsageDescription - Location while using app
✅ NSLocationAlwaysAndWhenInUseUsageDescription - Always location access
*/

/// ==============================================================
/// CONFIGURATION & CONSTANTS
/// ==============================================================
/*
Location Tracking:
- Update frequency: Every 3 meters (src: location_service.dart:32)
- Accuracy: High (GPS)
- Timeout: 10 seconds for first location

Speech Recognition (STT):
- Listen duration: Configured in app_constants.dart
- Language support: 4 languages (en, yo, ig, pidgin)

Text-to-Speech (TTS):
- Speech rate: 0.48 (slow, natural)
- Volume: 1.0 (max)
- Pitch: 1.05 (warm tone)

Map Trail:
- Max trail points: 500
- Min distance between points: 1 meter
- trail visibility: Light blue with 0.6 opacity during navigation
*/

/// ==============================================================
/// TROUBLESHOOTING
/// ==============================================================
/*
ISSUE: Microphone not working
SOLUTION:
- Check app has microphone permission in settings
- Verify AndroidManifest.xml includes RECORD_AUDIO
- Test with Settings > Check "Enable voice commands"
- Ensure device is not in silent mode for STT testing

ISSUE: Speaker not playing TTS
SOLUTION:
- Check device volume is not muted
- Verify MODIFY_AUDIO_SETTINGS permission granted
- Enable TTS in Settings screen
- Check language is supported on device (falls back to en-NG)

ISSUE: Trail not showing on map
SOLUTION:
- Ensure you're actually navigating (trail only shows during navigation)
- Check you have location permission enabled
- Move at least 3 meters to trigger location update
- Verify trail service is initialized in NavigationProvider

ISSUE: Location not updating
SOLUTION:
- Enable GPS on device
- Grant location permission to app
- Move at least 3 meters for update
- Check internet connection for map tiles
- Restart the app if stuck
*/

/// ==============================================================
/// FUTURE ENHANCEMENTS
/// ==============================================================
/*
1. Route history: Save and replay previous trails
2. Trail export: Export trail as GPX/KML for sharing
3. Speed tracking: Calculate walking speed from trail
4. Voice language selection: Choose TTS/STT language in settings
5. Trail animation: Replay trail movement with timestamps
6. Waypoint markers: Mark important stops during navigation
7. Offline speech: Download offline speech models
8. Voice feedback: Customizable voice alerts (distance, turns, etc.)
*/


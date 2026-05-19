# 🚀 Quick Reference: Native Features

## 📍 Where Everything Is

### 🎤 Voice Features (Microphone + Speaker)
```
Microphone Input
└─ lib/features/voice_assistant/services/speech_service.dart
   - listen() → Records voice, returns text
   - Uses: speech_to_text package

Speaker Output
└─ lib/features/voice_assistant/services/text_to_speech_service.dart
   - speak() → Converts text to speech
   - Uses: flutter_tts package

Voice Provider (Combines both)
└─ lib/features/voice_assistant/providers/voice_provider.dart
   - startListening() → Get voice input
   - speak() → Send voice output
   - State: idle, listening, processing, speaking, error

Voice FAB Button (User sees this)
└─ lib/features/voice_assistant/widgets/voice_fab.dart
   - Blue microphone button at bottom of screen
```

### 📍 Map Tracing (User Movement Trail)
```
Trail Service (Tracks movement)
└─ lib/features/navigation/services/map_trail_service.dart
   - addTrailPoint() → Add one point to trail
   - clearTrail() → Reset trail
   - trailPoints → Get all points
   - getTotalTrailDistance() → Get distance in km

Trail Integration
└─ lib/features/navigation/providers/navigation_provider.dart
   - trailService → Access trail manager
   - trailDistance → Get total distance traveled
   - osmPolylines → Returns both route + trail lines (for map)

Map Display
└─ lib/features/navigation/widgets/map_widget.dart
   - Renders all polylines (route + trail)
   - Updates when navigation provider changes
```

### 🗺️ Location Services
```
GPS Tracking
└─ lib/features/navigation/services/location_service.dart
   - getCurrentLocation() → One-time location fetch
   - trackLocation() → Stream of location updates (every 3 meters)
   - Parameters: accuracy, distance filter, timeout

Navigation Provider
└─ lib/features/navigation/providers/navigation_provider.dart
   - userLocation → Current GPS position
   - startLocationTracking() → Start listening for updates
   - _trailService → Trail updates happen here
```

---

## 🔄 How Everything Connects

```
┌─────────────────────────────────────────────────────────────┐
│                          MAP SCREEN                         │
│  (lib/features/navigation/screens/map_screen.dart)          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  MapWidget                                           │   │
│  │  Shows: Route (maroon) + Trail (light blue)          │   │
│  │  Gets data from: NavigationProvider                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  VoiceFab Button (Blue Microphone)                   │   │
│  │  Triggers: VoiceProvider.startListening()            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
             │                                    │
             ▼                                    ▼
   ┌──────────────────────┐        ┌──────────────────────┐
   │  VoiceProvider       │        │ NavigationProvider   │
   │                      │        │                      │
   │ • TTS Service        │        │ • TrailService       │
   │ • STT Service        │        │ • LocationService    │
   │ • State: speaking    │        │ • RouteService       │
   │   listening, etc.    │        │ • osmPolylines()     │
   │                      │        │ • trailDistance      │
   └──────────────────────┘        └──────────────────────┘
             │                                    │
             │                                    │
             ▼                                    ▼
   ┌─────────────────────────────────────────────────────┐
   │  Services & External APIs                           │
   ├─────────────────────────────────────────────────────┤
   │  • Flutter TTS (Speaker/Android & iOS)              │
   │  • Speech-to-Text (Mic/Android & iOS)               │
   │  • Geolocator (GPS/Android & iOS)                   │
   │  • Permission Handler (Request permissions)         │
   └─────────────────────────────────────────────────────┘
             │
             │
             ▼
   ┌─────────────────────────────────────────────────────┐
   │  Native Device Hardware                             │
   ├─────────────────────────────────────────────────────┤
   │  🎤 Microphone (records voice)                       │
   │  🔊 Speaker (outputs audio)                         │
   │  📍 GPS (provides location)                         │
   └─────────────────────────────────────────────────────┘
```

---

## 💻 Code Examples

### Example 1: Listen to User Voice Command
```dart
final voice = context.read<VoiceProvider>();

// User taps voice FAB
await voice.startListening();

// Voice provider internally:
// 1. Records audio using SpeechService
// 2. Recognizes text
// 3. Processes as VoiceCommand
// 4. Speaks response using TextToSpeechService
// 5. Calls onCommandResolved callback
```

### Example 2: Track User Movement Trail
```dart
final nav = context.read<NavigationProvider>();

// Navigation starts
nav.navigateTo(libraryLocation);
// → MapTrailService resets with current location

// User walks (location updates)
// → Location updates trigger
// → Points added to trail (if >1 meter apart)
// → osmPolylines updated
// → Map rerenders with trail visible

// Navigation ends
nav.cancelNavigation();
// → Trail cleared automatically
```

### Example 3: Display Map with Route + Trail
```dart
// In MapWidget
List<Polyline> polylines = navProvider.osmPolylines;
// Returns: [trail_polyline, route_polyline]

// Rendered as:
// - Light blue line = trail (your actual path)
// - Dark maroon line = route (optimal path)
```

---

## 🔌 Permissions Flow

### Android:
```
AndroidManifest.xml declares permissions
    ↓
User installs app (grants at install or prompt)
    ↓
SpeechService: Permission.microphone.request()
LocationService: PermissionsService.requestLocationPermission()
    ↓
Permission granted/denied
    ↓
App works or shows error message
```

### iOS:
```
Info.plist has permission descriptions
    ↓
User launches app
    ↓
First use of mic/location triggers system dialog
    ↓
User sees: "App needs microphone/location access"
    ↓
User clicks "Allow" or "Don't Allow"
    ↓
App records choice (can't ask again unless user resets)
```

---

## 🐛 Debugging Tips

### Voice not working:
```dart
// Check voice provider state
VoiceProvider voice = context.read<VoiceProvider>();
print(voice.state);  // Should be: idle, listening, speaking... or error

// Check error message
print(voice.errorMessage);  // Shows what went wrong

// Check recognition text
print(voice.recognizedText);  // What was recognized
```

### Trail not showing:
```dart
// Check if navigating
NavigationProvider nav = context.read<NavigationProvider>();
print(nav.isNavigating);  // Must be true

// Check trail points
print(nav.trailService.trailPoints.length);  // Should be > 0

// Check trail distance
print(nav.trailDistance);  // Should be > 0 if moved 3+ meters
```

### Location not updating:
```dart
// Check if GPS is on
Geolocator.isLocationServiceEnabled();

// Check current location
LatLng? loc = nav.userLocation;
print('${loc?.latitude}, ${loc?.longitude}');

// Check permission
Status status = await Permission.location.status;
print(status);  // granted, denied, etc.
```

---

## ⚙️ Configuration Points

| Feature | File | Setting | Value |
|---------|------|---------|-------|
| Voice Speed | TextToSpeechService.dart:21 | `setSpeechRate()` | 0.25-1.0 |
| Voice Pitch | TextToSpeechService.dart:23 | `setPitch()` | 0.5-2.0 |
| Voice Volume | TextToSpeechService.dart:22 | `setVolume()` | 0-1.0 |
| Location Update | LocationService.dart:32 | `distanceFilter` | Meters (3) |
| Location Accuracy | LocationService.dart:31 | `accuracy` | HIGH, BEST, etc. |
| Trail Max Points | MapTrailService.dart:9 | `_maxTrailLength` | Count (500) |
| Trail Min Distance | MapTrailService.dart:17 | Check `> 1` | Meters (1) |

---

## 📱 User Experience Flow

### Using Voice Navigation:
```
1. User sees map screen
2. User taps blue microphone button
3. App shows "Listening..." indicator
4. User speaks: "Navigate to Library"
5. App converts speech to text
6. App analyzes command
7. App speaks back: "Navigating to Library..."
8. Map updates:
   - Shows maroon route line
   - Shows user location (blue dot)
   - Shows destination (red pin)
   - Shows light blue trail as user walks
9. App announces when close: "You're getting close"
10. App announces arrival: "You have arrived"
11. Trail clears, navigation ends
```

---

## 🚦 State Transitions

### Voice Provider States:
```
idle ─→ listening ─→ processing ─→ speaking ─→ idle
  │                                              │
  └──────────────────────────── error ◄─────────┘
```

### Navigation States:
```
not_navigating ─→ navigating ─→ trail_visible ─→ not_navigating
                                                        │
                                    (on arrival announcement)
```

---

## 📊 Data Flow Example: Voice Command to Navigation

```
User speaks: "Navigate to Library"
     │
     ▼
SpeechService.listen()
     │
     ▼ Returns: "navigate to library"
VoiceCommandHandler.process()
     │
     ▼ Returns: VoiceCommand(
       │  type: navigate,
       │  resolvedLocation: Library_LatLng
       │)
     │
     ▼
MapScreen._handleVoiceCommand()
     │
     ▼
NavigationProvider.navigateTo(Library)
     │
     ├─→ MapTrailService.resetTrail()
     │
     ├─→ RouteService.getRoutePoints()
     │
     └─→ VoiceProvider.speak("Navigating to Library...")
          │
          ▼
    TextToSpeechService.speak()
          │
          ▼
    Device Speaker plays audio
```

---

## 🎯 Key Classes

| Class | File | Purpose |
|-------|------|---------|
| `SpeechService` | speech_service.dart | Records & recognizes voice |
| `TextToSpeechService` | text_to_speech_service.dart | Speaks text aloud |
| `VoiceProvider` | voice_provider.dart | Manages voice state |
| `MapTrailService` | map_trail_service.dart | Tracks & stores location trail |
| `NavigationProvider` | navigation_provider.dart | Manages nav + trail + route |
| `LocationService` | location_service.dart | Provides GPS updates |
| `RouteService` | route_service.dart | Calculates route points |

---

## ✨ Pro Tips

1. **Speech rate**: Set to 0.48 for natural speed, 0.6 for faster, 0.3 for slower
2. **Trail updates**: Happen every ~3 meters, so trail looks smooth without jank
3. **Memory efficient**: Trail auto-removes old points, max 500 points = ~20km trail
4. **Distance filter**: Increase to 5+ for less frequent updates = better battery life
5. **Offline mode**: All voice + location works offline (no internet needed)

---

## 🔗 Integration Checklist for New Features

Want to add something new? Follow this pattern:

1. **Create Service** → Handle the actual work
2. **Create Provider** → Manage service state
3. **Inject Provider** → Add to service locator
4. **Use in Widget** → Display in UI
5. **Handle Disposal** → Clean up resources

Example: Adding a "Record My Journey" feature
- Service: JourneyRecorderService (save/load trails)
- Provider: JourneyProvider (manage journeys)  
- Locator: Add to service_locator.dart
- Widget: Add journey list screen
- Disposal: Clean up file handles

---

**This reference should help you navigate the codebase quickly!** 🗺️✨


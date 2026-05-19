# 🎯 Native Phone Features Implementation
## Campus Navigation App - Speaker, Microphone & Map Tracing

### ✨ What's New

Your Covenant University Campus Navigation app now includes:

1. **🎤 Native Microphone** - Voice-controlled navigation using speech recognition
2. **🔊 Native Speaker** - Automatic voice directions and announcements
3. **📍 Map Tracing** - Real-time visualization of your walking path on the campus map

---

## 🚀 Quick Start

### A. Build & Run the App

```bash
cd C:\Users\Ibrah\StudioProjects\conventant_navigation

# Get dependencies
flutter pub get

# Run on Android
flutter run

# Or run on specific device
flutter devices
flutter run -d <device_id>
```

### B. Grant Permissions (First Run)

When app launches, grant these permissions:
- **Location** - For GPS tracking
- **Microphone** - For voice commands
- **Audio** - For voice announcements

---

## 🎤 Using the Voice Features

### Speaking Commands (Microphone)

1. **Tap the Voice FAB** (blue microphone button at bottom of map)
2. **Say your command** when the app shows "Listening..."
3. **Wait for response** - App speaks back and shows results

### Supported Commands:
```
"Navigate to Library"
"Show me the library"
"Take me to Academic building"
"Where am I?"
"Show hostels"
"Show food vendors"
"Search for the bookstore"
```

### Listening to Directions (Speaker)

The app will automatically speak:
- Welcome message when you open it
- Directions when navigation starts
- Distance and time estimates
- Arrival announcement when you reach destination

---

## 📍 Map Tracing - How It Works

### What You'll See:
- **Dark Red Route Line** = Planned path to destination
- **Light Blue Trail** = Actual path you've walked
- **Blue Dot** = Your current position
- **Red Pin** = Your destination

### Step-by-Step:
1. Open the app and wait for location to load
2. Tap on any campus location (e.g., "Library")
3. Say "Navigate to Library" OR tap "Navigate"
4. Watch the light blue trail appear as you walk
5. Compare your actual path vs. the planned route
6. Trail disappears when you arrive or cancel navigation

---

## ⚙️ Configuration

### Change TTS (Speaker) Settings:
Edit: `lib/features/voice_assistant/services/text_to_speech_service.dart`
```dart
await _tts.setSpeechRate(0.48);    // 0.25 to 1.0 (slower to faster)
await _tts.setVolume(1.0);         // 0 to 1.0
await _tts.setPitch(1.05);         // 0.5 to 2.0
```

### Change Location Update Frequency:
Edit: `lib/features/navigation/services/location_service.dart`
```dart
const LocationSettings settings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 3,  // Update every 3 meters (increase for fewer updates)
);
```

### Change Trail Behavior:
Edit: `lib/features/navigation/services/map_trail_service.dart`
```dart
final int _maxTrailLength = 500;  // Max points to store (higher = more memory)
```

---

## 🔐 Permissions

### Android
✅ **microphone** - Records voice commands
✅ **location** - GPS tracking for map
✅ **audio settings** - Controls speaker output

*All configured in: `android/app/src/main/AndroidManifest.xml`*

### iOS
✅ **NSMicrophoneUsageDescription** - Microphone request
✅ **NSSpeechRecognitionUsageDescription** - Speech recognition
✅ **NSLocationWhenInUseUsageDescription** - Location access

*All configured in: `ios/Runner/Info.plist`*

---

## 🛠️ Project Structure

```
lib/features/
├── voice_assistant/
│   ├── services/
│   │   ├── speech_service.dart          🎤 Microphone input
│   │   ├── text_to_speech_service.dart  🔊 Speaker output
│   │   └── voice_command_handler.dart   📝 Parse commands
│   └── providers/
│       └── voice_provider.dart          🎯 Voice state management
│
└── navigation/
    ├── services/
    │   ├── location_service.dart        📍 GPS tracking
    │   ├── route_service.dart
    │   └── map_trail_service.dart       🛤️ Trail tracking
    ├── providers/
    │   └── navigation_provider.dart     📍 Navigation state + trails
    └── screens/
        └── map_screen.dart              🗺️ Main UI
```

---

## 📱 Testing Checklist

- [ ] **Microphone Test**
  - [ ] Tap Voice FAB
  - [ ] Say "Navigate to Library"
  - [ ] See spoken response

- [ ] **Speaker Test**
  - [ ] Start navigation
  - [ ] Hear "Navigating to..." announcement
  - [ ] Volume is sufficient

- [ ] **Trail Test**
  - [ ] Start navigation
  - [ ] Move around campus
  - [ ] See blue trail following your movement
  - [ ] Trail matches your actual path

- [ ] **Permissions**
  - [ ] First launch shows permission requests
  - [ ] Denying permission shows helpful error
  - [ ] App works normally after granting

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Microphone not working | Check Android Settings → Permissions → Microphone (ALLOWED) |
| No voice output | Unmute phone, check volume, ensure speaker permission granted |
| Trail not visible | Ensure you're navigating, move at least 3 meters, check GPS |
| GPS stuck | Enable location, move outdoors, wait 10-15 seconds |
| Slow speech | Increase speech rate: `setSpeechRate(0.7)` |
| Can't understand voice | Speak clearly, check microphone isn't blocked |

---

## 🚀 Advanced Features

### Get Trail Statistics
```dart
final provider = context.read<NavigationProvider>();

// Get total distance walked
double kmWalked = provider.trailDistance;

// Get all trail points
List<LatLng> path = provider.trailService.trailPoints;

// Clear trail manually
provider.trailService.clearTrail();
```

### Custom TTS Pitch (Deeper/Higher Voice)
```dart
// Lower pitch = deeper voice
await _tts.setPitch(0.8);  // Deeper

// Higher pitch = higher voice
await _tts.setPitch(1.5);  // Higher
```

### Adjust STT Listening Timeout
Edit `core/constants/app_constants.dart`:
```dart
static const int voiceListenSeconds = 10;  // Change to 15, 20, etc.
```

---

## 📖 File Reference

| File | Purpose | Feature |
|------|---------|---------|
| `speech_service.dart` | Speech-to-text (microphone) | 🎤 Voice input |
| `text_to_speech_service.dart` | Text-to-speech (speaker) | 🔊 Voice output |
| `map_trail_service.dart` | Location trail tracking | 📍 Map tracing |
| `voice_provider.dart` | Voice state management | Combined voice control |
| `navigation_provider.dart` | Navigation + trail state | 📍 + 🛤️ integration |
| `AndroidManifest.xml` | Android permissions | 🔐 Android perms |
| `Info.plist` | iOS permissions & TTS config | 🔐 iOS perms |

---

## 🌟 Usage Tips

1. **Best Results:**
   - Speak clearly and naturally
   - Use location names from the campus
   - Stay indoors for better trail accuracy
   - Keep phone unlocked while navigating

2. **Battery Saving:**
   - Trail updates once per 3 meters (you can increase this)
   - GPS only active during navigation
   - Voice processing is local (no internet required after initial setup)

3. **Offline Mode:**
   - Voice commands work offline ✅
   - Map tiles cache automatically ✅
   - Location tracking works offline ✅
   - Voice announcements work offline ✅

---

## 🔗 Related Documentation

- See `NATIVE_FEATURES_GUIDE.dart` for technical details
- See `pubspec.yaml` for dependencies:
  - `speech_to_text` - Microphone
  - `flutter_tts` - Speaker
  - `geolocator` - Location
  - `latlong2` - GPS math

---

## 💡 Next Steps

You can enhance these features by:
1. Adding voice language selection in Settings
2. Recording and replaying your entire journey
3. Exporting trail as GPX format
4. Adding custom voice alerts for turns
5. Integrating with offline voice models

---

**Enjoy your enhanced campus navigation experience! 🎓📍**


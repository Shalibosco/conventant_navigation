# 🏗️ Architecture Diagrams

## 📐 System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                          FLUTTER APP                               │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                    MAP SCREEN (UI)                        │    │
│  │  • Shows map with route + trail                          │    │
│  │  • Voice FAB button                                      │    │
│  │  • Navigation panel                                      │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ▲  ▲  ▲                                   │
│                          │  │  │                                   │
│         ┌────────────────┤  │  └─────────────────┐                │
│         │                │  │                     │                │
│    ┌────▼──────┐    ┌───▼──┴──┐    ┌────────────▼─┐               │
│    │  Voice    │    │Navigation│    │ App State    │               │
│    │ Provider  │    │ Provider │    │  Provider    │               │
│    └────┬──────┘    └───┬──────┘    └──────┬───────┘               │
│         │                │                  │                      │
│    ┌────▼──────────┐ ┌──▼─────────────┐ ┌─▼──────────┐            │
│    │  Services    │ │  Services       │ │ Services   │            │
│    ├──────────────┤ ├─────────────────┤ ├────────────┤            │
│    │• SpeechSvc   │ │• LocationSvc    │ │• NetworkSvc│            │
│    │• TextToSpeech│ │• RouteSvc       │ │            │            │
│    │• CmdHandler  │ │• MapTrailSvc    │ │            │            │
│    └────┬──────────┘ └──┬─────────────┘ └─┬──────────┘            │
│         │                │                 │                       │
└─────────┼────────────────┼─────────────────┼───────────────────────┘
          │                │                 │
          ▼                ▼                 ▼
    ┌──────────┐      ┌─────────┐      ┌─────────┐
    │ Packages │      │ Packages│      │ Packages│
    ├──────────┤      ├─────────┤      ├─────────┤
    │speech_tts│      │geolocor │      │connectivity
    │flutter_ts│      │latlong2 │      │http
    │perm_hdlr │      │flutter_ │      │
    └──────────┘      │map      │      └─────────┘
         │            └─────────┘
         │                 │
         ▼                 ▼
    ┌──────────────────────────┐
    │  NATIVE DEVICE APIs      │
    ├──────────────────────────┤
    │ • Microphone 🎤           │
    │ • Speaker 🔊              │
    │ • GPS 📍                  │
    │ • Network 🌐              │
    └──────────────────────────┘
```

---

## 🔄 Data Flow Diagram

### Voice Command Flow
```
┌─────────────┐
│   User      │
│   speaks    │ "Navigate to Library"
└──────┬──────┘
       │
       ▼
┌──────────────────────────────┐
│  MapScreen (UI Layer)        │
│  • User taps voice FAB       │
│  • Calls VoiceProvider       │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  VoiceProvider               │
│  • Manages voice state       │
│  • Coordinates STT & TTS     │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  SpeechService (Microphone)  │
│  • Records audio             │
│  • Sends to speech_to_text   │
│  • Returns: "navigate to...  │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  VoiceCommandHandler         │
│  • Parses "navigate to..."   │
│  • Finds location            │
│  • Returns VoiceCommand      │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  NavigationProvider          │
│  • navigateTo(location)      │
│  • Starts navigation         │
│  • Resets trail              │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  TextToSpeechService (Speaker)
│  • Reads location name       │
│  • Converts to speech        │
│  • Plays audio               │
└──────┬───────────────────────┘
       │
       ▼
     🔊 User hears: "Navigating to Library"
```

### Location & Trail Flow
```
┌──────────────────────────┐
│  LocationService         │
│  • Requests GPS access   │ (geolocator package)
│  • Gets LatLng stream    │
└──────┬───────────────────┘
       │ Every 3+ meters
       ▼
┌──────────────────────────┐
│  NavigationProvider      │
│  • startLocationTracking │
│  • Updates userLocation  │
└──────┬───────────────────┘
       │ During navigation
       ▼
┌──────────────────────────┐
│  MapTrailService         │
│  • addTrailPoint()       │
│  • Filter points (>1m)   │
│  • Store in list         │
└──────┬───────────────────┘
       │ Points added to trail
       ▼
┌──────────────────────────┐
│  NavigationProvider      │
│  • osmPolylines getter   │
│  • Returns: route + trail│
└──────┬───────────────────┘
       │ Updates observers
       ▼
┌──────────────────────────┐
│  MapWidget               │
│  • Renders polylines     │
│  • Shows trail in blue   │
└──────┬───────────────────┘
       │
       ▼
    🗺️ User sees trail following their path
```

---

## 🎯 State Management Diagram

### VoiceProvider States
```
     ┌──────────┐
     │   IDLE   │ (initial state)
     └────┬─────┘
          │ startListening()
          ▼
     ┌──────────┐
     │LISTENING │ (waiting for voice)
     └────┬─────┘
          │ speech heard
          ▼
  ┌──────────────┐
  │ PROCESSING   │ (analyzing text)
  └────┬─────────┘
       │ ready to speak
       ▼
  ┌──────────────┐
  │  SPEAKING    │ (playing audio)
  └────┬─────────┘
       │ done speaking
       ▼
  ┌──────────────┐
  │    IDLE      │ (ready again)
  └──────────────┘
  
  Any state can jump to ERROR and recover
```

### NavigationProvider States
```
NOT_NAVIGATING
     │
     │ navigateTo(location)
     ▼
  NAVIGATING
     ├─ Trail: EMPTY → GROWING → FULL
     ├─ Route: HIDDEN → VISIBLE
     ├─ Marker: USER + DESTINATION visible
     └─ Updates: Live location + trail
          │
          │ cancelNavigation() OR arrival
          ▼
NOT_NAVIGATING
     └─ Trail cleared
```

### Trail States
```
NONE (empty list)
     │
     │ resetTrail()
     ▼
START (1 point)
     │
     │ addTrailPoint() x multiple
     ▼
GROWING (2-500 points)
     │
     ├─ Points > 500: FULL (removing old)
     │
     │ cancelNavigation()
     ▼
CLEARED (empty list)
```

---

## 🔌 Provider Dependency Injection

```
┌───────────────────────────────────┐
│  ServiceLocator (GetIt)           │
│  lib/core/di/service_locator.dart │
├───────────────────────────────────┤
│                                   │
│  Singleton Registrations:         │
│  • SpeechService                  │
│  • TextToSpeechService            │
│  • VoiceCommandHandler            │
│  • LocationService                │
│  • PermissionsService             │
│  • RouteService                   │
│  • LocationRepository             │
│  • NetworkService                 │
│                                   │
└───────────────────────────────────┘
         ▲  ▲  ▲
         │  │  └────────────────────────┐
         │  │                           │
         │  │  ┌──────────────────┐     │
         │  │  │ VoiceProvider    │     │
         │  │  │ uses: SpeechSvc, │     │
         │  │  │        TTSSvc,   │     │
         │  │  │        CmdHndlr  │     │
         │  └──┴──────────────────┘     │
         │                              │
         │  ┌──────────────────────┐    │
         │  │ NavigationProvider   │    │
         │  │ uses: LocationSvc,   │    │
         │  │        RouteSvc,     │    │
         │  │        Repository    │    │
         └──┴──────────────────────┘    │
                                        │
            ┌───────────────────────────┘
            │
            ▼
┌──────────────────────────┐
│  MapTrailService         │
│  (created locally in Nav)│
└──────────────────────────┘
```

---

## 📱 Widget Tree

```
CUNavigateApp (Root)
│
├─ MultiProvider
│  ├─ AppStateProvider
│  ├─ LanguageProvider
│  ├─ NavigationProvider ◄─ Contains MapTrailService
│  └─ VoiceProvider
│
└─ MaterialApp
   └─ AppRouter (Navigation)
      │
      └─ MapScreen (Main screen)
         │
         ├─ SlidingUpPanel
         │  └─ _NavigationPanel (shows during nav)
         │
         ├─ MapWidget
         │  └─ FlutterMap
         │     ├─ TileLayer (map tiles)
         │     ├─ PolylineLayer ◄─ Renders trail + route
         │     └─ MarkerLayer ◄─ User + destination markers
         │
         ├─ _SearchBar (top)
         │  └─ Search results dropdown
         │
         ├─ _CategoryChips (filter)
         │
         ├─ _MapFab buttons (right side)
         │  ├─ My Location button
         │  └─ Settings button
         │
         └─ VoiceFab (bottom) ◄─ Voice input button
            └─ Calls VoiceProvider.startListening()
```

---

## 🔐 Permission Flow

### Android
```
App Launch
  │
  ├─ Checks AndroidManifest.xml
  │  └─ Sees: <uses-permission ...>
  │
  ├─ On first use:
  │  └─ permission_handler prompts user
  │     ├─ "Allow" → Granted
  │     └─ "Deny" → Denied
  │
  └─ Uses in code:
     ├─ SpeechService: Permission.microphone.request()
     └─ LocationService: PermissionsService.requestLocationPermission()
```

### iOS
```
App Launch
  │
  ├─ Checks Info.plist
  │  └─ Sees: NSMicrophoneUsageDescription, etc.
  │
  ├─ On first use:
  │  └─ iOS shows native system prompt
  │     ├─ "Allow" → Granted
  │     └─ "Don't Allow" → Denied
  │
  └─ Services auto-request:
     ├─ SpeechService: permission_handler prompts
     └─ LocationService: Geolocator prompts
```

---

## 🎨 Color Scheme (Map Visualization)

```
┌─────────────────────────────────────┐
│         MAP DISPLAY                 │
├─────────────────────────────────────┤
│                                     │
│    [Dark Red Line: Route]           │
│    Represents: Optimal path         │
│    Color: #800000 (Maroon)          │
│    Width: 5.0                       │
│                                     │
│    [Light Blue Line: Trail]         │
│    Represents: Your actual path     │
│    Color: #4A90E2 (Light Blue)      │
│    Width: 3.0                       │
│    Opacity: 60%                     │
│                                     │
│    [Blue Dot: You]                  │
│    Represents: Current location     │
│    Color: Colors.blue               │
│    Size: 40x40                      │
│                                     │
│    [Red Pin: Destination]           │
│    Represents: Target building      │
│    Color: Colors.red                │
│    Size: 45x45                      │
│                                     │
└─────────────────────────────────────┘

Interpretation:
- Both lines showing → Navigation active
- Only blue dot moving → Location updating
- Blue trail follows you → GPS working well
- Gap between trail and route → You're off the optimal path
```

---

## 📊 Data Structure Diagram

### MapTrailService
```
MapTrailService
├─ _trailPoints: List<LatLng>
│  └─ [Point1, Point2, Point3, ..., Point500]
│     (each point is a latitude/longitude)
│
├─ _maxTrailLength: int = 500
│  └─ When exceeded, oldest point removed
│
└─ getters/methods:
   ├─ trailPoints: List<LatLng> (unmodifiable)
   ├─ hasTrail: bool
   ├─ addTrailPoint(LatLng)
   ├─ getTotalTrailDistance(): double
   └─ clearTrail()
```

### NavigationProvider (Navigation part)
```
NavigationProvider
├─ _trailService: MapTrailService
│  └─ Manages movement trail
│
├─ _userLocation: LatLng?
│  └─ Current GPS position
│
├─ _routePoints: List<LatLng>
│  └─ Route from user to destination
│
├─ _selectedDestination: LocationModel?
│  └─ Where user is navigating to
│
└─ osmPolylines: List<Polyline>
   ├─ Trail polyline (if navigating)
   │  └─ Light blue, 3.0 width
   │
   └─ Route polyline
      └─ Dark maroon, 5.0 width
```

---

## 🚀 Deployment Architecture

```
┌────────────────────────────────────────┐
│  DEVELOPMENT (Your Machine)            │
│  ├─ Source Code (Dart)                 │
│  ├─ Assets (Images, JSON)              │
│  └─ Configuration (pubspec.yaml)       │
└──────────┬─────────────────────────────┘
           │
           ├─ flutter build apk (Android)
           │  └─ APK file (installable)
           │
           ├─ flutter build ios (iOS)
           │  └─ IPA file (installable)
           │
           └─ flutter run (Debug)
              └─ Runs on device/emulator
```

---

## 🔄 Update Cycle (Runtime)

```
1. APP LAUNCH
   └─ Initialize services
   └─ Load locations
   └─ Request permissions
   └─ Show map

2. USER TAPS LOCATION
   └─ NavigationProvider.navigateTo()
   └─ MapTrailService.resetTrail()
   └─ RouteService.getRoutePoints()
   └─ Update osmPolylines
   └─ Map redraws

3. USER WALKS
   └─ LocationService.trackLocation() emits
   └─ NavigationProvider receives update
   └─ MapTrailService.addTrailPoint()
   └─ Update osmPolylines
   └─ Map redraws (trail grows)

4. ARRIVAL
   └─ Distance < 15m check triggered
   └─ VoiceProvider.speak() announcement
   └─ NavigationProvider.cancelNavigation()
   └─ MapTrailService.clearTrail()
   └─ Map redraws (trail gone)

5. USER TAPS VOICE
   └─ Enable listening
   └─ SpeechService.listen()
   └─ Wait for speech
   └─ Recognize text
   └─ VoiceCommandHandler.process()
   └─ Execute command
   └─ TextToSpeechService.speak()
   └─ Return to navigation
```

---

**All diagrams show the complete architecture of native features integration!** 📐✨


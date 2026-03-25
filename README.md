# CU Navigate 🗺️

> An interactive campus navigation and information app for **Covenant University, Ota, Ogun State, Nigeria** — built with Flutter.

---

## 📱 Overview

**CU Navigate** helps students, staff, and visitors find their way around the Covenant University campus with ease. It features an interactive map, voice-guided navigation, multilingual support in four languages, and works offline once map tiles are cached.

---

## ✨ Features

### 🗺️ Campus Map
- Interactive OpenStreetMap-powered campus map
- 15+ campus locations marked with category icons (academic, hostel, worship, food, sports, admin, medical, recreation)
- Tap any marker to view location details and start navigation
- Filter locations by category using quick-filter chips
- Search bar with live dropdown results

### 🧭 Navigation
- Walking route generation using the OSRM routing engine
- Real-time GPS tracking with live user position on map
- Distance and estimated walk time display
- Offline fallback — straight-line route when internet is unavailable
- Recenter button to snap map back to user location

### 🎙️ Voice Assistant
- Speak to navigate — say *"Go to Chapel of Light"* or *"Find the library"*
- Speech-to-text input with live partial results display
- Text-to-speech responses in the selected language
- Supports natural language commands:
    - `"Navigate to [location]"` — start navigation
    - `"Where am I?"` — center map on user location
    - `"Show all hostels"` — filter by category
    - `"Help"` — list available commands

### 🌍 Multilingual Support
Four fully supported languages across the entire app UI and voice assistant:

| Language | Code | Voice Support |
|---|---|---|
| English (Nigerian) | `en` | ✅ |
| Yorùbá | `yo` | ✅ |
| Igbo | `ig` | ✅ |
| Nigerian Pidgin | `pidgin` | ✅ |

### 📋 Campus Information
- Tabbed information browser with categories: Rules, Facilities, Contacts, Events
- Expandable info cards with localized content
- Covers chapel policy, dress code, health centre, library hours, registry, ICT support and more

### ⚙️ Settings
- Language switcher with instant app-wide effect
- Dark/Light theme toggle with persistent preference
- Offline map tile management — view cache size, clear cache, download campus tiles
- App version and university information

### 📡 Offline Support
- Map tiles cached locally for 30 days after first load
- All campus location data bundled as a local JSON asset
- Campus info available fully offline
- Graceful fallback routing when internet is unavailable
- Offline banner shown when connectivity is lost

---

## 🏛️ Campus Locations Included

| Location | Category |
|---|---|
| Chapel of Light | Worship |
| University Library | Academic |
| CST Building | Academic |
| College of Management Sciences | Academic |
| Male Hostel (Daniel Hall) | Hostel |
| Female Hostel (Deborah Hall) | Hostel |
| University Cafeteria | Food |
| Student Health Centre | Medical |
| Sports Complex | Sports |
| Registry Office | Admin |
| Vice Chancellor's Office | Admin |
| Main Gate | Admin |
| Student Lounge | Recreation |
| ICT Centre | Academic |
| Staff Quarters | Admin |

---

## 🏗️ Architecture

The app follows **Feature-First Clean Architecture** with clear separation between data, domain, and presentation layers.

```
lib/
├── core/                          # App-wide utilities
│   ├── constants/                 # App constants & campus coordinates
│   ├── di/                        # Dependency injection (get_it)
│   ├── error/                     # Typed exceptions & failures
│   ├── routes/                    # Named route navigation
│   ├── services/                  # Core services (storage, network, permissions)
│   ├── theme/                     # Light & dark theme definitions
│   └── utils/                     # Helper functions
│
├── data/                          # Data layer
│   ├── datasources/               # Local JSON & Hive data sources
│   ├── models/                    # LocationModel (Hive), InfoModel
│   └── repositories/              # Repository pattern with failure handling
│
├── features/                      # Feature modules
│   ├── navigation/                # Map, GPS, routing, search
│   ├── voice_assistant/           # STT, TTS, command processing
│   ├── multilingual/              # Language switching & JSON localization
│   ├── information/               # Campus info browser
│   └── settings/                  # App settings screen
│
├── presentation/                  # Shared/global widgets & providers
│   ├── providers/                 # App-level state (theme, connectivity)
│   └── widgets/                   # Reusable UI components
│
└── main.dart                      # App entry point
```

### State Management
- **Provider** — feature-level state (`NavigationProvider`, `VoiceProvider`, `LanguageProvider`)
- **get_it** — dependency injection and service location

### Data Flow
```
JSON Asset / Hive Cache
       ↓
  DataSource
       ↓
  Repository  ←→  (Failure / Success)
       ↓
  Provider (ChangeNotifier)
       ↓
  Widget (Consumer / context.watch)
```

---

## 🛠️ Tech Stack

| Category | Package | Version |
|---|---|---|
| Map rendering | `flutter_map` | ^6.1.0 |
| Map coordinates | `latlong2` | ^0.9.0 |
| Tile caching | `flutter_map_cache` | ^1.1.0 |
| GPS location | `geolocator` | ^11.0.0 |
| Speech to text | `speech_to_text` | ^7.0.0 |
| Text to speech | `flutter_tts` | ^4.0.2 |
| Local database | `hive` + `hive_flutter` | ^2.2.3 |
| Preferences | `shared_preferences` | ^2.2.2 |
| State management | `provider` | ^6.1.2 |
| Dependency injection | `get_it` | ^7.6.7 |
| Connectivity | `connectivity_plus` | ^6.0.0 |
| HTTP client | `http` | ^1.2.0 |
| Animations | `flutter_animate` | ^4.5.0 |
| Fonts | `google_fonts` | ^6.2.1 |
| Routing engine | OSRM (public API) | — |
| Map tiles | OpenStreetMap | — |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.3.0`
- Dart SDK `>=3.3.0`
- Android Studio or VS Code
- Android device or emulator (API 21+)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/your-username/covenant_navigation.git
cd covenant_navigation
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Generate Hive adapters**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**4. Run the app**
```bash
flutter run
```

### Android Permissions

Ensure the following permissions are present in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 📁 Asset Structure

```
assets/
├── images/
│   └── convenant.png          # University logo
├── map/
│   ├── covenant_locations.json  # 15 campus locations with coordinates
│   └── campus_info.json         # Campus rules, facilities, contacts
└── lang/
    ├── en.json                  # English strings
    ├── yo.json                  # Yorùbá strings
    ├── ig.json                  # Igbo strings
    └── pidgin.json              # Nigerian Pidgin strings
```

### Adding New Campus Locations

Edit `assets/map/covenant_locations.json` and add an entry following this structure:

```json
{
  "id": "loc_016",
  "name": "New Building Name",
  "description": "Brief description of the location.",
  "latitude": 6.6722,
  "longitude": 3.1600,
  "category": "academic",
  "openingHours": "Mon–Fri: 8 AM–5 PM",
  "tags": ["keyword1", "keyword2"],
  "localizedNames": {
    "yo": "Yoruba name here",
    "ig": "Igbo name here",
    "pidgin": "Pidgin name here"
  },
  "localizedDescriptions": {
    "yo": "Yoruba description here",
    "ig": "Igbo description here",
    "pidgin": "Pidgin description here"
  }
}
```

Valid category values: `academic` · `hostel` · `worship` · `food` · `sports` · `admin` · `medical` · `recreation`

---

## 🎙️ Voice Command Reference

| Command | Language | Action |
|---|---|---|
| *"Go to Chapel of Light"* | English | Navigate to location |
| *"Where am I?"* | English | Center on user location |
| *"Show all hostels"* | English | Filter hostel markers |
| *"Find the library"* | English | Search and navigate |
| *"Help"* | English | List available commands |
| *"Lọ sí Library"* | Yorùbá | Navigate to location |
| *"Ibo ni mo wà?"* | Yorùbá | Where am I |
| *"Gaa Chapel of Light"* | Igbo | Navigate to location |
| *"Ebe nọ m?"* | Igbo | Where am I |
| *"Take me go Library"* | Pidgin | Navigate to location |
| *"Wia I dey?"* | Pidgin | Where am I |

---

## 🌙 Theme

The app ships with both **light** and **dark** themes using Covenant University's brand colours:

| Token | Colour | Usage |
|---|---|---|
| Primary | `#1A3C6E` | CU Deep Blue — buttons, headers, markers |
| Secondary | `#D4AF37` | CU Gold — accents, tab indicators |
| Accent | `#2ECC71` | Navigation green — routes, active states |
| Error | `#E74C3C` | Errors, rule category tags |

---

## 🗺️ Campus Coordinates

| Property | Value |
|---|---|
| Centre latitude | `6.6722` |
| Centre longitude | `3.1600` |
| Default zoom | `16.5` |
| Boundary North | `6.6780` |
| Boundary South | `6.6660` |
| Boundary East | `3.1680` |
| Boundary West | `3.1520` |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch — `git checkout -b feature/new-feature`
3. Commit your changes — `git commit -m 'Add new feature'`
4. Push to the branch — `git push origin feature/new-feature`
5. Open a Pull Request

---

## 📄 License

This project is developed for **Covenant University, Ota, Nigeria**.  
Map data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright).  
Routing powered by [OSRM](http://project-osrm.org/).

---

## 👨‍💻 Developer Notes

- Map tiles are served by OpenStreetMap and cached locally for offline use. Tile cache expires after **30 days**.
- The OSRM routing API is a free public service — for production use, consider self-hosting or using a paid routing service.
- Nigerian Pidgin uses the `en-NG` TTS voice as no dedicated Pidgin TTS engine is currently available on Android.
- Voice recognition accuracy for Yorùbá and Igbo depends on device support. English (Nigerian) gives the most consistent results.
- All location data is bundled in the app — no backend server is required.

---

*Built with ❤️ for Covenant University students and staff.*
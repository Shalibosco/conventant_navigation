# ❓ Troubleshooting & FAQ

## 🎤 Microphone Issues

### Q: "Microphone button doesn't respond"
**A:** 
1. Check device is not in silent mode (switch on side of phone)
2. Verify microphone permission is granted:
   - Android: Settings → Apps → Permissions → Microphone → Allowed
   - iOS: Settings → Privacy → Microphone → App → Allow
3. Test with device speaker first (easier to debug than voice)
4. Check app has focus (click on app window)

### Q: "I speak but nothing happens"
**A:**
1. Speak louder and more clearly
2. Wait for "Listening..." indicator to appear
3. Check phone isn't muted
4. Try indoors (outdoor noise can confuse speech recognition)
5. Ensure you speak actual location names from campus

### Q: "App recognizes wrong words"
**A:**
1. Speak each word slowly and distinctly
2. Avoid background noise
3. Use exact location names from the map
4. Try alternative names (e.g., "Main Library" vs "Library")
5. Check device language matches what you're speaking

### Q: "Microphone works but speaker doesn't respond"
**A:**
1. Check speaker is not muted (side switch)
2. Increase device volume
3. Check app volume is not muted in app settings
4. Go to Settings and enable voice
5. Restart the app

### Q: "Non-English language doesn't work"
**A:**
1. Verify device has language pack installed
2. Check language code is in app constants
3. Try speaking English as fallback
4. Restart phone to refresh language data

**Error Message: "Microphone permission denied"**
```
Solutions:
1. Go to phone Settings
2. Find "Apps" or "Applications"  
3. Find "Campus Navigation" app
4. Tap "Permissions"
5. Enable "Microphone"
6. Restart the app
```

---

## 🔊 Speaker Issues

### Q: "I don't hear any voice announcements"
**A:**
1. Unmute phone (check side switch)
2. Increase volume (use volume buttons)
3. Check app isn't muted in settings
4. Restart the app
5. Check speaker isn't covered or blocked

### Q: "Voice is too fast/slow/robotic"
**A:** Contact developer - can adjust speech rate/pitch in code:
```
File: lib/features/voice_assistant/services/text_to_speech_service.dart
Line 21: setSpeechRate(0.48)  ← Change to 0.3 (slower) or 0.7 (faster)
Line 23: setPitch(1.05)       ← Change to 0.8 (deeper) or 1.5 (higher)
```

### Q: "Wrong language is speaking"
**A:**
1. Go to Settings in app
2. Check language is set to your preferred language
3. Restart app
4. Test with small phrase first

**Error Message: "Speech not available"**
```
Solutions:
1. Check internet connection
2. Restart app
3. Restart phone
4. Check device has TTS engine installed:
   Android: Settings → Language & Input → Text-to-Speech
   iOS: Settings → Accessibility → Speech
5. Try installing language pack if not available
```

---

## 📍 Location & GPS Issues

### Q: "Map doesn't show my location / blue dot not moving"
**A:**
1. Ensure location permission is granted
2. Turn on device GPS (not just network)
3. Wait 10-15 seconds for GPS fix
4. Move outdoors if possible (GPS works better outside)
5. Check app has location permission:
   - Android: Settings → Apps → Permissions → Location → Allow
   - iOS: Settings → Privacy → Location → App → Allow Always

### Q: "Trail not showing on map"
**A:**
1. Confirm you're actively navigating (not just viewing map)
2. Move at least 3-5 meters to register movement
3. Wait 1-2 seconds for trail to render
4. Check GPS location is actually updating (blue dot moving)
5. Check app isn't in background

### Q: "GPS location stuck/not updating"
**A:**
1. Enable Location Services on phone
2. Grant location permission to app
3. Move to open area (outdoors better than indoors)
4. Disable and re-enable Location Services
5. Restart the app
6. Reboot phone if still stuck

### Q: "Route shows but trail is empty"
**A:**
1. You must be in active navigation for trail to show
2. Move at least 1 meter to add first point
3. Continue moving to see trail develop
4. Check location is actually changing:
   - Click "My Location" button
   - See if blue dot moves when you walk

**Error Message: "Location access denied"**
```
Solutions:
1. Go to Settings
2. Find "Apps" or "Applications"
3. Find "Campus Navigation" 
4. Tap "Permissions"
5. Enable "Location"
6. Choose "Allow all the time" for background tracking
7. Restart the app
```

---

## 🗺️ Map & Navigation Issues

### Q: "Route line doesn't show"
**A:**
1. Navigate to a location first (select destination)
2. Ensure you have valid GPS location
3. Check destination is valid location on campus
4. Route appears after location is locked
5. May take 1-2 seconds to calculate

### Q: "Trail and route overlap, hard to see"
**A:**
- Route = Dark Maroon (#800000) - Planned optimal path
- Trail = Light Blue (#4A90E2) - Your actual path
- This is normal! Shows if you followed the route or took different path

### Q: "Map doesn't update when walking"
**A:**
1. Wait for GPS location update (updates every 3+ meters)
2. Move slowly - app needs to detect movement
3. Ensure app is in foreground (open and visible)
4. Check internet for map tiles (needs wifi/mobile data)
5. Restart app if stuck

---

## 🎯 Voice Command Issues

### Q: "Voice command understood but action didn't happen"
**A:**
1. Check navigation panel opened (navigation started)
2. Verify location name was recognized correctly
3. Check if location exists on campus
4. Try exact name from map (not variations)
5. Try again - sometimes takes 2-3 tries

### Q: "App understood command but took wrong action"
**A:**
Examples & solutions:
```
Said: "Navigate to Library"
Did:  Nothing / Wrong location

Solutions:
- Specify full name: "Navigate to Main Library"
- Use category: "Show me Academic buildings"
- Spell it out: "Show me the L-I-B-R-A-R-Y"
- Use map to select manually instead
```

### Q: "Voice command makes app crash"
**A:**
1. Note exactly what you said
2. Try simpler command
3. Restart the app
4. Report as bug with exact phrase used

**Error: "Voice recognition not available"**
```
Solutions:
1. Check internet connection
2. Verify microphone permission granted
3. Restart app
4. Restart phone
5. Check device language settings
```

---

## ⚙️ Settings & Configuration Issues

### Q: "How do I change voice language?"
**A:**
1. Open app Settings (gear icon, top right)
2. Look for "Language" option
3. Select preferred language
4. Restart app
5. Voice will now use selected language

### Q: "How do I disable voice features?"
**A:**
1. Open Settings
2. Look for "Voice Announcements"
3. Toggle OFF
4. Restart app
5. Voice features will be silent (but still functional)

---

## 💻 Developer Issues

### Q: "Code compiles but voice doesn't work"
**A:**
Check service locator initialization:
```dart
File: lib/core/di/service_locator.dart

Must have:
- sl.registerSingleton<SpeechService>(SpeechService())
- sl.registerSingleton<TextToSpeechService>(TextToSpeechService())
- sl.registerSingleton<VoiceCommandHandler>(VoiceCommandHandler())
```

### Q: "Trail service not found / import error"
**A:**
```dart
Need import:
import 'package:conventant_navigation/features/navigation/services/map_trail_service.dart';

Or use in NavigationProvider:
import '../services/map_trail_service.dart';
```

### Q: "Permissions not working on Android"
**A:**
Verify AndroidManifest.xml has:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Q: "iOS says permission denied"
**A:**
Check Info.plist has these keys:
```
NSMicrophoneUsageDescription
NSSpeechRecognitionUsageDescription  
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
```

---

## 🆘 General Troubleshooting Steps

### For ANY issue, try in this order:
1. **Check Permissions**
   - Android: Settings → Apps → [App] → Permissions
   - iOS: Settings → Privacy → [Permission Type]

2. **Restart App**
   - Close app completely (swipe away from recent)
   - Wait 3 seconds
   - Reopen app

3. **Restart Device**
   - Power off phone completely
   - Wait 10 seconds
   - Power back on
   - Reopen app

4. **Check Internet**
   - Maps need internet for tiles
   - Open browser, visit google.com
   - If web doesn't work, internet is off

5. **Check Settings**
   - Ensure GPS is ON
   - Ensure Bluetooth is ON (if using BT speaker)
   - Ensure Location Services is ON

6. **Update App**
   - Delete app
   - Reinstall latest version
   - Grant all permissions

7. **Contact Support**
   - Note exact error message
   - Include what you were doing
   - Provide device type & OS version

---

## 📞 When Asking for Help

Include this information:
- **Device**: iPhone/Android, Model, OS Version
- **App Version**: Check in Settings
- **What happened**: Exact steps you took
- **What you expected**: What should have happened
- **Error message**: Copy exact error text
- **Screenshot**: If applicable

Example:
```
Device: Android Samsung Galaxy S20, Android 12
App Version: 1.0.0
Issue: Voice command for "Library" doesn't navigate

Steps:
1. Tapped voice button (blue mic)
2. Said "Navigate to Library"
3. App spoke back "Finding Library"
4. But map didn't open navigation panel

Expected: Should show navigation panel with "Library" selected
Error: None visible
```

---

## 🔧 Advanced Debugging

### Check Voice State:
```dart
final voice = context.read<VoiceProvider>();
debugPrint('State: ${voice.state}');
debugPrint('Recognized: ${voice.recognizedText}');
debugPrint('Error: ${voice.errorMessage}');
debugPrint('Speaking: ${voice.isSpeaking}');
```

### Check Navigation State:
```dart
final nav = context.read<NavigationProvider>();
debugPrint('Navigating: ${nav.isNavigating}');
debugPrint('Location: ${nav.userLocation}');
debugPrint('Trail points: ${nav.trailService.trailPoints.length}');
debugPrint('Has route: ${nav.hasRoute}');
```

### Check Location:
```dart
final nav = context.read<NavigationProvider>();
if (nav.userLocation != null) {
  debugPrint('{${nav.userLocation!.latitude}, ${nav.userLocation!.longitude}}');
} else {
  debugPrint('Location not yet available');
}
```

---

## ✅ Verification Checklist

Before reporting a bug, confirm:
- [ ] Phone is NOT in silent mode
- [ ] Volume is turned UP (not zero)
- [ ] Location permission is GRANTED
- [ ] Microphone permission is GRANTED
- [ ] GPS is ON and has a fix (try moving around)
- [ ] You're speaking clearly and slowly
- [ ] Location name matches map exactly
- [ ] You moved at least 3-5 meters for trail
- [ ] App is in Foreground (not background)
- [ ] Internet is working (try browser)

---

## 🎓 Common Misconceptions

### "The app needs internet for voice"
❌ Wrong - Voice works offline
✅ Correct - Maps need internet for tiles, but voice is local

### "I need to be shouting for it to work"
❌ Wrong - Normal speaking voice is fine
✅ Correct - Speak clearly and at normal volume

### "Trail appears immediately"
❌ Wrong - Trail needs movement to show
✅ Correct - Trail shows after you move 3+ meters

### "I need to grant permission every time"
❌ Wrong - Granted once, stays granted
✅ Correct - Android prompts once, iOS same

### "Trail works anywhere"
❌ Wrong - Needs GPS which works best outdoors
✅ Correct - Works indoors but less accurate

---

**Still having issues?**

1. Check the NATIVE_FEATURES_GUIDE.dart file
2. Review SETUP_NATIVE_FEATURES.md
3. Check QUICK_REFERENCE.md for code structure
4. Look at IMPLEMENTATION_SUMMARY.md for what was added

**Found a bug?** Note down exactly when/where it happens, and what device you're using! 🐛


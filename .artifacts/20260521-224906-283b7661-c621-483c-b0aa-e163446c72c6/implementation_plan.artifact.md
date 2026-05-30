# Fix Yoruba, Igbo and Pidgin Language Support

The user reported that Yoruba and Igbo language options "did not work". Investigation revealed that while translation files exist, most of the UI text is hardcoded in English, and the Voice Assistant does not update its internal language state when the user switches languages in the settings. Additionally, the translation files (`en.json`, `yo.json`, `ig.json`, `pidgin.json`) use inconsistent keys, leading to missing translations even when a language is selected.

## Proposed Changes

### 1. Synchronize Translation Files
Update all JSON files in `assets/lang/` to use a consistent schema of keys. This ensures that every localized string available in one language is also available in others.

#### [en.json](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/assets/lang/en.json)
- Rewrite to match the schema used by other languages.

#### [yo.json](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/assets/lang/yo.json), [ig.json](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/assets/lang/ig.json), [pidgin.json](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/assets/lang/pidgin.json)
- Ensure all keys from the new schema are present and correctly translated.

---

### 2. UI Localization
Update UI components to use `context.t(key)` instead of hardcoded strings.

#### [map_screen.dart](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/lib/features/navigation/screens/map_screen.dart)
- Localize search hint, category chips, navigation panel stats, and buttons.

#### [settings_screen.dart](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/lib/features/settings/screens/settings_screen.dart)
- Localize section headers, titles, and descriptions.
- **Critical Fix**: Update `onTap` for language selection to also call `voiceProvider.setLanguage(code)`.

#### [info_screen.dart](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/lib/features/information/screens/info_screen.dart)
- Localize tab labels and app bar title.

#### [voice_screen.dart](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/lib/features/voice_assistant/screens/voice_screen.dart)
- Localize titles and prompts.

#### [app_drawer.dart](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/lib/presentation/widgets/app_drawer.dart)
- Localize navigation items and section headers.
- **Critical Fix**: Update `onTap` for language selection to also call `voiceProvider.setLanguage(code)`.

---

### 3. Localization Delegate Improvements

#### [app_localization.dart](file:///C:/Users/Ibrah/StudioProjects/conventant_navigation/lib/features/multilingual/localization/app_localization.dart)
- Update `isSupported` to explicitly include all supported locale codes for clarity.

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure no regressions in core logic (if existing tests exist).

### Manual Verification
1. **Language Switching**: Open Settings, switch to Yoruba/Igbo/Pidgin, and verify that the UI (App Bar, Search Hint, Drawer, Tabs) updates immediately.
2. **Voice Assistant Language**: After switching to Yoruba, open the Voice Assistant and verify that it says "Speak in Yorùbá" and correctly processes Yoruba commands (e.g., "mu mi lo sí EIE").
3. **Persistency**: Change language, restart the app, and verify the selected language is remembered and correctly applied to both UI and Voice Assistant.

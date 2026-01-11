// lib/main.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/multilingual/language_provider.dart';
import 'features/voice_assistant/voice_pro.dart';
import 'features/navigation/screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(const CovenantNavigatorApp());
}

Future<void> initHive() async {
  // Hive initialization for offline storage
  // await Hive.initFlutter();
  // await Hive.openBox('app_data');
}

class CovenantNavigatorApp extends StatelessWidget {
  const CovenantNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'Covenant Navigator',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
            locale: Locale(languageProvider.currentLanguage),
            supportedLocales: const [
              Locale('en', 'US'), // English
              Locale('yo', 'NG'), // Yoruba
              Locale('ig', 'NG'), // Igbo
            ],
            // Localizations delegates are automatically included in MaterialApp
            home: const MapScreen(),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/multilingual/language_provider.dart';
import '../../features/voice_assistant/voice_pro.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _offlineMode = true;
  bool _voiceEnabled = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final voiceProvider = Provider.of<VoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Language Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: languageProvider.currentLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Select Language',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('English'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'yo',
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Yoruba'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ig',
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Igbo'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        languageProvider.changeLanguage(value);
                        voiceProvider.setLanguage(value == 'en'
                            ? 'en-US'
                            : value == 'yo'
                            ? 'yo-NG'
                            : 'ig-NG');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Offline Mode'),
                    subtitle: const Text('Use maps without internet'),
                    value: _offlineMode,
                    onChanged: (value) {
                      setState(() {
                        _offlineMode = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Voice Assistant'),
                    subtitle: const Text('Enable voice commands'),
                    value: _voiceEnabled,
                    onChanged: (value) {
                      setState(() {
                        _voiceEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Show navigation alerts'),
                    value: _notifications,
                    onChanged: (value) {
                      setState(() {
                        _notifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.map),
                    title: const Text('Download Offline Map'),
                    subtitle: const Text('Download campus map for offline use'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Download map tiles
                      },
                      child: const Text('Download'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Clear downloaded map data'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Clear cache
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
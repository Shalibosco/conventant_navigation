import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Information'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Covenant University Navigator',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'This app helps you navigate around Covenant University campus in Ota, Nigeria.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Interactive Campus Map'),
              ),
              ListTile(
                leading: Icon(Icons.volume_up),
                title: Text('Voice Assistant'),
              ),
              ListTile(
                leading: Icon(Icons.language),
                title: Text('Multi-language Support'),
              ),
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Offline Mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
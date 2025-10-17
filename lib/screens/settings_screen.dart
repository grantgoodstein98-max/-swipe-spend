import 'package:flutter/material.dart';

/// Screen for managing categories and app settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Category Settings Coming Soon!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

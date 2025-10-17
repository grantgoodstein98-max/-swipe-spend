import 'package:flutter/material.dart';

/// Screen for viewing spending charts and analytics
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Overview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Charts Coming Soon!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

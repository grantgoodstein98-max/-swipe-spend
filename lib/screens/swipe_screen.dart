import 'package:flutter/material.dart';

/// Screen for swiping to categorize transactions
class SwipeScreen extends StatelessWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorize Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Swipe Interface Coming Soon!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Chip widget for suggested prompts
class SuggestedPromptChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const SuggestedPromptChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
        elevation: 2,
        pressElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';

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
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final categories = categoryProvider.categories;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Swipe Mapping',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure which category each swipe direction triggers',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 24),

              // Swipe direction cards
              _buildSwipeDirectionCard(
                context,
                'Swipe Up',
                Icons.arrow_upward,
                model.SwipeDirection.up,
                categories,
                categoryProvider,
              ),
              const SizedBox(height: 16),
              _buildSwipeDirectionCard(
                context,
                'Swipe Down',
                Icons.arrow_downward,
                model.SwipeDirection.down,
                categories,
                categoryProvider,
              ),
              const SizedBox(height: 16),
              _buildSwipeDirectionCard(
                context,
                'Swipe Left',
                Icons.arrow_back,
                model.SwipeDirection.left,
                categories,
                categoryProvider,
              ),
              const SizedBox(height: 16),
              _buildSwipeDirectionCard(
                context,
                'Swipe Right',
                Icons.arrow_forward,
                model.SwipeDirection.right,
                categories,
                categoryProvider,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwipeDirectionCard(
    BuildContext context,
    String title,
    IconData icon,
    model.SwipeDirection direction,
    List<model.Category> categories,
    CategoryProvider categoryProvider,
  ) {
    // Get currently mapped category for this direction
    final categoryId = categoryProvider.getCategoryForSwipe(direction);
    final currentCategory = categoryId != null
        ? categoryProvider.getCategoryById(categoryId)
        : null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Direction icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),

            // Direction label and current category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (currentCategory != null)
                    Row(
                      children: [
                        Icon(
                          currentCategory.icon,
                          size: 16,
                          color: currentCategory.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentCategory.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: currentCategory.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No category assigned',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                ],
              ),
            ),

            // Change button
            OutlinedButton(
              onPressed: () => _showCategoryPicker(
                context,
                title,
                direction,
                categories,
                categoryProvider,
              ),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    String directionTitle,
    model.SwipeDirection direction,
    List<model.Category> categories,
    CategoryProvider categoryProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select category for $directionTitle',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...categories.map((category) {
                // Check if this category is currently mapped to this direction
                final isCurrentlyMapped =
                    categoryProvider.getCategoryForSwipe(direction) == category.id;
                return ListTile(
                  leading: Icon(
                    category.icon,
                    color: category.color,
                  ),
                  title: Text(category.name),
                  trailing: isCurrentlyMapped
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    categoryProvider.mapSwipeToCategory(direction, category.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$directionTitle → ${category.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: category.color,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

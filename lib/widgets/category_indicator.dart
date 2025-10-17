import 'package:flutter/material.dart';
import '../models/category.dart' as model;

/// Widget that displays category indicators around the swipe area
class CategoryIndicator extends StatelessWidget {
  final List<model.Category> categories;
  final Map<model.SwipeDirection, String> swipeMappings;
  final Map<String, double> categoryTotals;

  const CategoryIndicator({
    super.key,
    required this.categories,
    required this.swipeMappings,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    // Get categories currently mapped to each direction
    final upCategoryId = swipeMappings[model.SwipeDirection.up];
    final downCategoryId = swipeMappings[model.SwipeDirection.down];
    final leftCategoryId = swipeMappings[model.SwipeDirection.left];
    final rightCategoryId = swipeMappings[model.SwipeDirection.right];

    final upCategory =
        upCategoryId != null ? _getCategoryById(upCategoryId) : null;
    final downCategory =
        downCategoryId != null ? _getCategoryById(downCategoryId) : null;
    final leftCategory =
        leftCategoryId != null ? _getCategoryById(leftCategoryId) : null;
    final rightCategory =
        rightCategoryId != null ? _getCategoryById(rightCategoryId) : null;

    return Stack(
      children: [
        // Top indicators (swipe up)
        if (upCategory != null)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 32,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 8),
                _buildCategoryChip(upCategory),
              ],
            ),
          ),

        // Bottom indicators (swipe down)
        if (downCategory != null)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildCategoryChip(downCategory),
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 32,
                  color: Colors.grey.withOpacity(0.4),
                ),
              ],
            ),
          ),

        // Left indicators (swipe left)
        if (leftCategory != null)
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 32,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(leftCategory),
              ],
            ),
          ),

        // Right indicators (swipe right)
        if (rightCategory != null)
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                _buildCategoryChip(rightCategory),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 32,
                  color: Colors.grey.withOpacity(0.4),
                ),
              ],
            ),
          ),
      ],
    );
  }

  model.Category? _getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Widget _buildCategoryChip(model.Category category) {
    final total = categoryTotals[category.id] ?? 0.0;
    final totalText = total > 0 ? '\$${total.toStringAsFixed(2)}' : '\$0.00';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: category.color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 16,
                color: category.color,
              ),
              const SizedBox(width: 4),
              Text(
                category.name,
                style: TextStyle(
                  color: category.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            totalText,
            style: TextStyle(
              color: category.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

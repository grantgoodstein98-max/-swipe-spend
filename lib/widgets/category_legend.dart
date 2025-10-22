import 'package:flutter/material.dart';
import '../models/category.dart' as model;

/// A persistent legend showing swipe directions and their assigned categories
/// Split across both sides of the screen with arrows indicating swipe directions
class CategoryLegend extends StatelessWidget {
  final Map<model.SwipeDirection, String>? swipeMappings;
  final List<model.Category>? categories;

  const CategoryLegend({
    super.key,
    this.swipeMappings,
    this.categories,
  });

  model.Category? _getCategoryForDirection(model.SwipeDirection direction) {
    if (categories == null || swipeMappings == null) return null;
    final categoryId = swipeMappings![direction];
    if (categoryId == null) return null;
    try {
      return categories!.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildLegendItem(model.Category category, IconData arrowIcon, {bool isLeftSide = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeftSide
            ? [
                // Left side: Arrow first, then category
                Icon(
                  arrowIcon,
                  color: category.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: category.color.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: category.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]
            : [
                // Right side: Category first, then arrow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: category.color.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: category.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  arrowIcon,
                  color: category.color,
                  size: 20,
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get categories for each direction
    final leftCategory = _getCategoryForDirection(model.SwipeDirection.left);
    final topLeftCategory = _getCategoryForDirection(model.SwipeDirection.topLeft);
    final bottomLeftCategory = _getCategoryForDirection(model.SwipeDirection.bottomLeft);

    final rightCategory = _getCategoryForDirection(model.SwipeDirection.right);
    final topRightCategory = _getCategoryForDirection(model.SwipeDirection.topRight);
    final bottomRightCategory = _getCategoryForDirection(model.SwipeDirection.bottomRight);

    final upCategory = _getCategoryForDirection(model.SwipeDirection.up);
    final downCategory = _getCategoryForDirection(model.SwipeDirection.down);

    return Stack(
      children: [
        // Left side legend
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Up (added to left side)
                  if (upCategory != null)
                    _buildLegendItem(upCategory, Icons.arrow_upward, isLeftSide: true),

                  if (upCategory != null && topLeftCategory != null)
                    const SizedBox(height: 6),

                  // Top-left
                  if (topLeftCategory != null)
                    _buildLegendItem(topLeftCategory, Icons.north_west, isLeftSide: true),

                  if (topLeftCategory != null && leftCategory != null)
                    const SizedBox(height: 6),

                  // Left
                  if (leftCategory != null)
                    _buildLegendItem(leftCategory, Icons.arrow_back, isLeftSide: true),

                  if (leftCategory != null && bottomLeftCategory != null)
                    const SizedBox(height: 6),

                  // Bottom-left
                  if (bottomLeftCategory != null)
                    _buildLegendItem(bottomLeftCategory, Icons.south_west, isLeftSide: true),
                ],
              ),
            ),
          ),
        ),

        // Right side legend
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Top-right
                  if (topRightCategory != null)
                    _buildLegendItem(topRightCategory, Icons.north_east, isLeftSide: false),

                  if (topRightCategory != null && rightCategory != null)
                    const SizedBox(height: 6),

                  // Right
                  if (rightCategory != null)
                    _buildLegendItem(rightCategory, Icons.arrow_forward, isLeftSide: false),

                  if (rightCategory != null && bottomRightCategory != null)
                    const SizedBox(height: 6),

                  // Bottom-right
                  if (bottomRightCategory != null)
                    _buildLegendItem(bottomRightCategory, Icons.south_east, isLeftSide: false),

                  if (bottomRightCategory != null && downCategory != null)
                    const SizedBox(height: 6),

                  // Down (added to right side)
                  if (downCategory != null)
                    _buildLegendItem(downCategory, Icons.arrow_downward, isLeftSide: false),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

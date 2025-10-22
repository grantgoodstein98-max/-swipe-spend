import 'package:flutter/material.dart';
import '../models/category.dart' as model;

/// A persistent legend showing swipe directions and their assigned categories
/// Split across both sides of the screen with arrows indicating swipe directions
class CategoryLegend extends StatefulWidget {
  final Map<model.SwipeDirection, String>? swipeMappings;
  final List<model.Category>? categories;

  const CategoryLegend({
    super.key,
    this.swipeMappings,
    this.categories,
  });

  @override
  State<CategoryLegend> createState() => _CategoryLegendState();
}

class _CategoryLegendState extends State<CategoryLegend> {
  bool _isLeftExpanded = true;
  bool _isRightExpanded = true;

  model.Category? _getCategoryForDirection(model.SwipeDirection direction) {
    if (widget.categories == null || widget.swipeMappings == null) return null;
    final categoryId = widget.swipeMappings![direction];
    if (categoryId == null) return null;
    try {
      return widget.categories!.firstWhere((c) => c.id == categoryId);
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

  Widget _buildCollapsibleLegend({
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
    required bool isLeftSide,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: isExpanded ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isExpanded ? null : 6,
        width: isExpanded ? null : 40,
        padding: isExpanded ? const EdgeInsets.all(12) : const EdgeInsets.symmetric(vertical: 3, horizontal: 20),
        decoration: BoxDecoration(
          color: isExpanded
              ? theme.cardColor.withOpacity(0.95)
              : theme.colorScheme.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(isExpanded ? 12 : 6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: isExpanded
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isLeftSide ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: children,
                  ),
                  // Minimize button in top corner
                  Positioned(
                    top: 4,
                    right: isLeftSide ? 4 : null,
                    left: isLeftSide ? null : 4,
                    child: GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700.withOpacity(0.8)
                              : Colors.grey.shade300.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.minimize,
                          size: 10,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
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

    // Build left side children
    final leftChildren = <Widget>[];
    if (upCategory != null) {
      leftChildren.add(_buildLegendItem(upCategory, Icons.arrow_upward, isLeftSide: true));
    }
    if (upCategory != null && topLeftCategory != null) {
      leftChildren.add(const SizedBox(height: 6));
    }
    if (topLeftCategory != null) {
      leftChildren.add(_buildLegendItem(topLeftCategory, Icons.north_west, isLeftSide: true));
    }
    if (topLeftCategory != null && leftCategory != null) {
      leftChildren.add(const SizedBox(height: 6));
    }
    if (leftCategory != null) {
      leftChildren.add(_buildLegendItem(leftCategory, Icons.arrow_back, isLeftSide: true));
    }
    if (leftCategory != null && bottomLeftCategory != null) {
      leftChildren.add(const SizedBox(height: 6));
    }
    if (bottomLeftCategory != null) {
      leftChildren.add(_buildLegendItem(bottomLeftCategory, Icons.south_west, isLeftSide: true));
    }

    // Build right side children
    final rightChildren = <Widget>[];
    if (topRightCategory != null) {
      rightChildren.add(_buildLegendItem(topRightCategory, Icons.north_east, isLeftSide: false));
    }
    if (topRightCategory != null && rightCategory != null) {
      rightChildren.add(const SizedBox(height: 6));
    }
    if (rightCategory != null) {
      rightChildren.add(_buildLegendItem(rightCategory, Icons.arrow_forward, isLeftSide: false));
    }
    if (rightCategory != null && bottomRightCategory != null) {
      rightChildren.add(const SizedBox(height: 6));
    }
    if (bottomRightCategory != null) {
      rightChildren.add(_buildLegendItem(bottomRightCategory, Icons.south_east, isLeftSide: false));
    }
    if (bottomRightCategory != null && downCategory != null) {
      rightChildren.add(const SizedBox(height: 6));
    }
    if (downCategory != null) {
      rightChildren.add(_buildLegendItem(downCategory, Icons.arrow_downward, isLeftSide: false));
    }

    return Stack(
      children: [
        // Left side legend
        if (leftChildren.isNotEmpty)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildCollapsibleLegend(
                isExpanded: _isLeftExpanded,
                onToggle: () => setState(() => _isLeftExpanded = !_isLeftExpanded),
                children: leftChildren,
                isLeftSide: true,
                context: context,
              ),
            ),
          ),

        // Right side legend
        if (rightChildren.isNotEmpty)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildCollapsibleLegend(
                isExpanded: _isRightExpanded,
                onToggle: () => setState(() => _isRightExpanded = !_isRightExpanded),
                children: rightChildren,
                isLeftSide: false,
                context: context,
              ),
            ),
          ),
      ],
    );
  }
}

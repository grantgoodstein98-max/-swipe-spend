import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart' as model;

/// A card widget that displays transaction details
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final double? horizontalOffsetPercentage;
  final double? verticalOffsetPercentage;
  final List<model.Category>? categories;
  final Map<model.SwipeDirection, String>? swipeMappings;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.horizontalOffsetPercentage,
    this.verticalOffsetPercentage,
    this.categories,
    this.swipeMappings,
    this.onDelete,
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

  @override
  Widget build(BuildContext context) {
    // Calculate swipe direction and strength
    final horizontal = horizontalOffsetPercentage ?? 0;
    final vertical = verticalOffsetPercentage ?? 0;

    // Determine PRIMARY swipe direction (only show ONE icon at a time)
    final absDx = horizontal.abs();
    final absDy = vertical.abs();

    // Check if horizontal or vertical is primary
    final isHorizontalPrimary = absDx > absDy;
    final isVerticalPrimary = absDy > absDx;

    // Initialize all opacities to 0
    double rightOpacity = 0.0;
    double leftOpacity = 0.0;
    double upOpacity = 0.0;
    double downOpacity = 0.0;

    // Only show ONE direction icon based on primary axis
    if (isHorizontalPrimary && horizontal > 0.1) {
      // Swiping right
      rightOpacity = (horizontal * 2).clamp(0.0, 1.0);
    } else if (isHorizontalPrimary && horizontal < -0.1) {
      // Swiping left
      leftOpacity = (horizontal.abs() * 2).clamp(0.0, 1.0);
    } else if (isVerticalPrimary && vertical < -0.1) {
      // Swiping up
      upOpacity = (vertical.abs() * 2).clamp(0.0, 1.0);
    } else if (isVerticalPrimary && vertical > 0.1) {
      // Swiping down
      downOpacity = (vertical * 2).clamp(0.0, 1.0);
    }

    // Get categories for each direction
    final rightCategory = _getCategoryForDirection(model.SwipeDirection.right);
    final leftCategory = _getCategoryForDirection(model.SwipeDirection.left);
    final upCategory = _getCategoryForDirection(model.SwipeDirection.up);
    final downCategory = _getCategoryForDirection(model.SwipeDirection.down);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      // FIXED SIZE - All cards will be exactly the same dimensions
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Main card with Apple-style design
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF38383A).withOpacity(0.5)
                    : Colors.black.withOpacity(0.08),
                width: isDark ? 0.5 : 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Merchant icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Transaction name/merchant - Apple headline style
                Text(
                  transaction.merchantName ?? transaction.name,
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Amount - Large, bold, monospaced
                Text(
                  transaction.formattedAmount,
                  style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 18,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(height: 6),

                // Date - Subtle badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaction.formattedDate,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                const SizedBox(height: 6),

                // Swipe instruction
                Text(
                  'Swipe to categorize',
                  style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),

          // Right swipe icon
        if (rightOpacity > 0 && rightCategory != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: rightOpacity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: rightCategory.color.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: rightCategory.color.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: rightCategory.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rightCategory.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Left swipe icon
        if (leftOpacity > 0 && leftCategory != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: leftOpacity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: leftCategory.color.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: leftCategory.color.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: leftCategory.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        leftCategory.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Up swipe icon
        if (upOpacity > 0 && upCategory != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: upOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: upCategory.color.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: upCategory.color.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: upCategory.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        upCategory.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Down swipe icon
        if (downOpacity > 0 && downCategory != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: downOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: downCategory.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        downCategory.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: downCategory.color.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: downCategory.color.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Delete button (only show if onDelete callback is provided)
        if (onDelete != null)
          Positioned(
            top: 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withOpacity(0.2)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

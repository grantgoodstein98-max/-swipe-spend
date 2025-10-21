import 'dart:ui';
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

  IconData _getMerchantIcon(String merchantName) {
    final name = merchantName.toLowerCase();
    if (name.contains('amazon') || name.contains('walmart') || name.contains('target')) {
      return Icons.shopping_bag_rounded;
    } else if (name.contains('restaurant') || name.contains('cafe') || name.contains('pizza') || name.contains('food')) {
      return Icons.restaurant_rounded;
    } else if (name.contains('gas') || name.contains('shell') || name.contains('chevron')) {
      return Icons.local_gas_station_rounded;
    } else if (name.contains('uber') || name.contains('lyft') || name.contains('taxi')) {
      return Icons.directions_car_rounded;
    } else if (name.contains('netflix') || name.contains('spotify') || name.contains('subscription')) {
      return Icons.subscriptions_rounded;
    } else if (name.contains('bank') || name.contains('atm') || name.contains('transfer')) {
      return Icons.account_balance_rounded;
    } else if (name.contains('health') || name.contains('pharmacy') || name.contains('medical')) {
      return Icons.local_hospital_rounded;
    }
    return Icons.store_rounded;
  }

  Color _getMerchantIconColor(String merchantName) {
    final name = merchantName.toLowerCase();
    if (name.contains('amazon')) return const Color(0xFFFF9900);
    if (name.contains('walmart')) return const Color(0xFF0071CE);
    if (name.contains('target')) return const Color(0xFFCC0000);
    if (name.contains('starbucks')) return const Color(0xFF00704A);
    if (name.contains('mcdonald')) return const Color(0xFFFFC72C);
    if (name.contains('netflix')) return const Color(0xFFE50914);
    if (name.contains('spotify')) return const Color(0xFF1DB954);
    if (name.contains('uber')) return const Color(0xFF000000);
    return const Color(0xFF007AFF); // Default blue
  }

  @override
  Widget build(BuildContext context) {
    // Calculate swipe direction and strength
    final horizontal = horizontalOffsetPercentage ?? 0;
    final vertical = verticalOffsetPercentage ?? 0;

    // Determine PRIMARY swipe direction (only show ONE icon at a time)
    final absDx = horizontal.abs();
    final absDy = vertical.abs();

    // Initialize all opacities to 0
    double rightOpacity = 0.0;
    double leftOpacity = 0.0;
    double upOpacity = 0.0;
    double downOpacity = 0.0;
    double topLeftOpacity = 0.0;
    double topRightOpacity = 0.0;
    double bottomLeftOpacity = 0.0;
    double bottomRightOpacity = 0.0;

    // Diagonal threshold - both dx and dy must be significant (> 0.1)
    final isDiagonal = absDx > 0.1 && absDy > 0.1;

    // Check if it's a diagonal swipe based on ratio
    // If dx and dy are similar (within 40-250% ratio), it's diagonal
    final ratio = absDx > 0 ? absDy / absDx : 0;
    final isDiagonalRatio = ratio > 0.4 && ratio < 2.5;

    // Determine which direction icon to show
    if (isDiagonal && isDiagonalRatio) {
      // DIAGONAL SWIPES - corner directions
      final strength = ((absDx + absDy) / 2 * 2).clamp(0.0, 1.0);

      if (horizontal > 0 && vertical < 0) {
        // Top-right corner
        topRightOpacity = strength;
      } else if (horizontal < 0 && vertical < 0) {
        // Top-left corner
        topLeftOpacity = strength;
      } else if (horizontal < 0 && vertical > 0) {
        // Bottom-left corner
        bottomLeftOpacity = strength;
      } else if (horizontal > 0 && vertical > 0) {
        // Bottom-right corner
        bottomRightOpacity = strength;
      }
    } else {
      // CARDINAL SWIPES - only show if clearly horizontal or vertical
      final isHorizontalPrimary = absDx > absDy;
      final isVerticalPrimary = absDy > absDx;

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
    }

    // Get categories for each direction (all 8)
    final rightCategory = _getCategoryForDirection(model.SwipeDirection.right);
    final leftCategory = _getCategoryForDirection(model.SwipeDirection.left);
    final upCategory = _getCategoryForDirection(model.SwipeDirection.up);
    final downCategory = _getCategoryForDirection(model.SwipeDirection.down);
    final topLeftCategory = _getCategoryForDirection(model.SwipeDirection.topLeft);
    final topRightCategory = _getCategoryForDirection(model.SwipeDirection.topRight);
    final bottomLeftCategory = _getCategoryForDirection(model.SwipeDirection.bottomLeft);
    final bottomRightCategory = _getCategoryForDirection(model.SwipeDirection.bottomRight);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final merchantName = transaction.merchantName ?? transaction.name;
    final merchantIcon = _getMerchantIcon(merchantName);
    final merchantColor = _getMerchantIconColor(merchantName);

    return Stack(
        children: [
          // Main card with enhanced design
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1C1C1E),
                        const Color(0xFF2C2C2E),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF38383A).withOpacity(0.5)
                    : Colors.black.withOpacity(0.06),
                width: isDark ? 0.5 : 1.5,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: merchantColor.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Merchant icon with gradient background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        merchantColor,
                        merchantColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: merchantColor.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    merchantIcon,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Transaction name/merchant
                Text(
                  merchantName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),

                // Amount - Larger and more prominent
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.formattedAmount,
                    style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                  ),
                ),
                const SizedBox(height: 4),

                // Date and time badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 8,
                        color: theme.textTheme.labelSmall?.color,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        transaction.formattedDate,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // Swipe instruction with icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: merchantColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: merchantColor.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        size: 9,
                        color: merchantColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Swipe to categorize',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: merchantColor,
                        ),
                      ),
                    ],
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

        // Top-Left corner swipe icon
        if (topLeftOpacity > 0 && topLeftCategory != null)
          Positioned(
            top: 20,
            left: 20,
            child: Opacity(
              opacity: topLeftOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: topLeftCategory.color.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: topLeftCategory.color.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.north_west,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: topLeftCategory.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      topLeftCategory.name,
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

        // Top-Right corner swipe icon
        if (topRightOpacity > 0 && topRightCategory != null)
          Positioned(
            top: 20,
            right: 20,
            child: Opacity(
              opacity: topRightOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: topRightCategory.color.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: topRightCategory.color.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.north_east,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: topRightCategory.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      topRightCategory.name,
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

        // Bottom-Left corner swipe icon
        if (bottomLeftOpacity > 0 && bottomLeftCategory != null)
          Positioned(
            bottom: 20,
            left: 20,
            child: Opacity(
              opacity: bottomLeftOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bottomLeftCategory.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bottomLeftCategory.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bottomLeftCategory.color.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: bottomLeftCategory.color.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.south_west,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom-Right corner swipe icon
        if (bottomRightOpacity > 0 && bottomRightCategory != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: Opacity(
              opacity: bottomRightOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bottomRightCategory.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bottomRightCategory.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bottomRightCategory.color.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: bottomRightCategory.color.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.south_east,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
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
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/category.dart' as model;

/// Overlay widget that displays category indicators around the card swipe area
/// This is a separate widget positioned outside of the transaction cards
class CategoryIndicatorsOverlay extends StatelessWidget {
  final double? horizontalOffsetPercentage;
  final double? verticalOffsetPercentage;
  final Map<model.SwipeDirection, String>? swipeMappings;
  final List<model.Category>? categories;

  const CategoryIndicatorsOverlay({
    super.key,
    this.horizontalOffsetPercentage,
    this.verticalOffsetPercentage,
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

  /// Calculate proximity-based opacity for each indicator
  /// Based on angular distance from swipe vector to indicator direction
  double _calculateProximityOpacity(double swipeAngle, double targetAngle, double swipeMagnitude) {
    // If no swipe at all, indicators are invisible
    if (swipeMagnitude == 0) {
      return 0.0; // Completely invisible when card is at rest
    }

    // If very small swipe, start fading in at base opacity
    if (swipeMagnitude < 0.05) {
      return 0.35 * (swipeMagnitude / 0.05); // Gradually fade in from 0 to 0.35
    }

    // Calculate angular difference (0-180 degrees)
    var angleDiff = (swipeAngle - targetAngle).abs();
    if (angleDiff > 180) angleDiff = 360 - angleDiff;

    // Map angular difference to opacity with smooth falloff
    // 0° = 1.0 opacity (perfect match)
    // 45° = 0.7 opacity (adjacent)
    // 90° = 0.4 opacity (perpendicular)
    // 135° = 0.25 opacity (far)
    // 180° = 0.2 opacity (opposite)
    double proximityOpacity;
    if (angleDiff <= 45) {
      // Close match - linear interpolation from 1.0 to 0.7
      proximityOpacity = 1.0 - (angleDiff / 45) * 0.3;
    } else if (angleDiff <= 90) {
      // Medium distance - interpolate from 0.7 to 0.4
      proximityOpacity = 0.7 - ((angleDiff - 45) / 45) * 0.3;
    } else if (angleDiff <= 135) {
      // Far - interpolate from 0.4 to 0.25
      proximityOpacity = 0.4 - ((angleDiff - 90) / 45) * 0.15;
    } else {
      // Opposite side - interpolate from 0.25 to 0.2
      proximityOpacity = 0.25 - ((angleDiff - 135) / 45) * 0.05;
    }

    // Scale by swipe magnitude for smooth fade-in
    final magnitudeFactor = (swipeMagnitude * 1.5).clamp(0.0, 1.0);
    return (proximityOpacity * magnitudeFactor).clamp(0.0, 1.0);
  }

  Widget _buildIndicator(model.Category category, IconData icon, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate swipe direction and strength
    final horizontal = horizontalOffsetPercentage ?? 0;
    final vertical = verticalOffsetPercentage ?? 0;

    // Calculate swipe magnitude and angle
    final swipeMagnitude = sqrt(horizontal * horizontal + vertical * vertical);

    // Calculate swipe angle in degrees (0° = right, 90° = up, 180° = left, 270° = down)
    // Note: vertical is inverted in screen coordinates, so we negate it
    final swipeAngle = atan2(-vertical, horizontal) * 180 / pi;
    final normalizedAngle = swipeAngle < 0 ? swipeAngle + 360 : swipeAngle;

    // Define target angles for each direction (in degrees)
    const rightAngle = 0.0;      // →
    const upAngle = 90.0;         // ↑
    const leftAngle = 180.0;      // ←
    const downAngle = 270.0;      // ↓
    const topRightAngle = 45.0;   // ↗
    const topLeftAngle = 135.0;   // ↖
    const bottomLeftAngle = 225.0; // ↙
    const bottomRightAngle = 315.0; // ↘

    // Calculate proximity-based opacity for ALL indicators
    final rightOpacity = _calculateProximityOpacity(normalizedAngle, rightAngle, swipeMagnitude);
    final upOpacity = _calculateProximityOpacity(normalizedAngle, upAngle, swipeMagnitude);
    final leftOpacity = _calculateProximityOpacity(normalizedAngle, leftAngle, swipeMagnitude);
    final downOpacity = _calculateProximityOpacity(normalizedAngle, downAngle, swipeMagnitude);
    final topRightOpacity = _calculateProximityOpacity(normalizedAngle, topRightAngle, swipeMagnitude);
    final topLeftOpacity = _calculateProximityOpacity(normalizedAngle, topLeftAngle, swipeMagnitude);
    final bottomLeftOpacity = _calculateProximityOpacity(normalizedAngle, bottomLeftAngle, swipeMagnitude);
    final bottomRightOpacity = _calculateProximityOpacity(normalizedAngle, bottomRightAngle, swipeMagnitude);

    // Get categories for each direction (all 8)
    final rightCategory = _getCategoryForDirection(model.SwipeDirection.right);
    final leftCategory = _getCategoryForDirection(model.SwipeDirection.left);
    final upCategory = _getCategoryForDirection(model.SwipeDirection.up);
    final downCategory = _getCategoryForDirection(model.SwipeDirection.down);
    final topLeftCategory = _getCategoryForDirection(model.SwipeDirection.topLeft);
    final topRightCategory = _getCategoryForDirection(model.SwipeDirection.topRight);
    final bottomLeftCategory = _getCategoryForDirection(model.SwipeDirection.bottomLeft);
    final bottomRightCategory = _getCategoryForDirection(model.SwipeDirection.bottomRight);

    return Stack(
      children: [
        // Right indicator
        if (rightCategory != null)
          Positioned(
            right: 50,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildIndicator(rightCategory, Icons.arrow_forward, rightOpacity),
            ),
          ),

        // Left indicator
        if (leftCategory != null)
          Positioned(
            left: 50,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildIndicator(leftCategory, Icons.arrow_back, leftOpacity),
            ),
          ),

        // Up indicator
        if (upCategory != null)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _buildIndicator(upCategory, Icons.arrow_upward, upOpacity),
            ),
          ),

        // Down indicator
        if (downCategory != null)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _buildIndicator(downCategory, Icons.arrow_downward, downOpacity),
            ),
          ),

        // Top-Left indicator
        if (topLeftCategory != null)
          Positioned(
            top: 50,
            left: 50,
            child: _buildIndicator(topLeftCategory, Icons.north_west, topLeftOpacity),
          ),

        // Top-Right indicator
        if (topRightCategory != null)
          Positioned(
            top: 50,
            right: 50,
            child: _buildIndicator(topRightCategory, Icons.north_east, topRightOpacity),
          ),

        // Bottom-Left indicator
        if (bottomLeftCategory != null)
          Positioned(
            bottom: 50,
            left: 50,
            child: _buildIndicator(bottomLeftCategory, Icons.south_west, bottomLeftOpacity),
          ),

        // Bottom-Right indicator
        if (bottomRightCategory != null)
          Positioned(
            bottom: 50,
            right: 50,
            child: _buildIndicator(bottomRightCategory, Icons.south_east, bottomRightOpacity),
          ),
      ],
    );
  }
}

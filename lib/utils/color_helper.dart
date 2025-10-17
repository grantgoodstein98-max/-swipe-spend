import 'package:flutter/material.dart';

/// Helper functions for color adjustments and contrast calculations
class ColorHelper {
  /// Adjust color for dark mode to ensure visibility
  /// Reduces saturation by 20% and increases brightness by 10%
  static Color adjustColorForTheme(Color color, bool isDarkMode) {
    if (!isDarkMode) return color;

    final hslColor = HSLColor.fromColor(color);
    return hslColor
        .withSaturation((hslColor.saturation * 0.8).clamp(0.0, 1.0))
        .withLightness((hslColor.lightness * 1.1).clamp(0.0, 1.0))
        .toColor();
  }

  /// Get contrasting text color (white or black) based on background luminance
  /// Ensures text is readable on colored backgrounds
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    // If background is dark (low luminance), use white text
    // If background is light (high luminance), use black text
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Calculate relative luminance of a color
  /// Used for WCAG contrast calculations
  static double calculateLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Check if two colors have sufficient contrast (WCAG AA compliant)
  /// Returns true if contrast ratio is at least 4.5:1 for normal text
  static bool hasSufficientContrast(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    return contrastRatio >= 4.5;
  }

  /// Darken a color by a given amount (0.0 to 1.0)
  static Color darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Lighten a color by a given amount (0.0 to 1.0)
  static Color lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Create a semi-transparent overlay color
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get a lighter shade for hover/focus states
  static Color getHoverColor(Color color) {
    return lighten(color, 0.1);
  }

  /// Get a darker shade for pressed states
  static Color getPressedColor(Color color) {
    return darken(color, 0.1);
  }
}

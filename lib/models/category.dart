import 'package:flutter/material.dart';
import '../utils/available_icons.dart';

/// Direction of swipe gesture
enum SwipeDirection {
  up,
  down,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Represents a spending category
class Category {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;

  Category({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
  });

  /// Convert Category to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'iconName': iconName,
    };
  }

  /// Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
      iconName: json['iconName'] as String,
    );
  }

  /// Get Color object from hex string
  Color get color {
    final hexColor = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  /// Get IconData from icon name
  IconData get icon {
    return AvailableIcons.getIcon(iconName);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, name: $name}';
  }

  /// Create default categories for initial setup
  static List<Category> createDefaultCategories() {
    return [
      Category(
        id: '1',
        name: 'Food',
        colorHex: 'FF5722',
        iconName: 'restaurant',
      ),
      Category(
        id: '2',
        name: 'Transport',
        colorHex: '2196F3',
        iconName: 'directions_car',
      ),
      Category(
        id: '3',
        name: 'Shopping',
        colorHex: 'E91E63',
        iconName: 'shopping_bag',
      ),
      Category(
        id: '4',
        name: 'Entertainment',
        colorHex: '9C27B0',
        iconName: 'movie',
      ),
      Category(
        id: '5',
        name: 'Bills',
        colorHex: 'FFC107',
        iconName: 'receipt',
      ),
      Category(
        id: '6',
        name: 'Health',
        colorHex: '4CAF50',
        iconName: 'local_hospital',
      ),
      Category(
        id: '7',
        name: 'Home',
        colorHex: '795548',
        iconName: 'home',
      ),
      Category(
        id: '8',
        name: 'Other',
        colorHex: '607D8B',
        iconName: 'category',
      ),
    ];
  }

  /// Get default swipe mappings for all 8 directions
  static Map<SwipeDirection, String> getDefaultSwipeMappings() {
    return {
      // Main directions
      SwipeDirection.up: '1',            // Food
      SwipeDirection.down: '8',          // Other (locked - cannot be unmapped)
      SwipeDirection.left: '3',          // Shopping
      SwipeDirection.right: '4',         // Entertainment
      // Corner directions
      SwipeDirection.topLeft: '5',       // Bills
      SwipeDirection.topRight: '6',      // Health
      SwipeDirection.bottomLeft: '7',    // Home
      SwipeDirection.bottomRight: '2',   // Transport
    };
  }
}

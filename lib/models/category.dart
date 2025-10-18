import 'package:flutter/material.dart';
import '../utils/available_icons.dart';

/// Direction of swipe gesture
enum SwipeDirection { up, down, left, right }

/// Represents a spending category
class Category {
  final String id;
  final String name;
  final String colorHex;
  final SwipeDirection swipeDirection;
  final String iconName;

  Category({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.swipeDirection,
    required this.iconName,
  });

  /// Convert Category to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'swipeDirection': swipeDirection.toString().split('.').last,
      'iconName': iconName,
    };
  }

  /// Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
      swipeDirection: SwipeDirection.values.firstWhere(
        (e) => e.toString().split('.').last == json['swipeDirection'],
      ),
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
    return 'Category{id: $id, name: $name, swipeDirection: $swipeDirection}';
  }

  /// Create default categories for initial setup
  static List<Category> createDefaultCategories() {
    return [
      Category(
        id: '1',
        name: 'Food',
        colorHex: 'FF5722',
        swipeDirection: SwipeDirection.up,
        iconName: 'restaurant',
      ),
      Category(
        id: '2',
        name: 'Transport',
        colorHex: '2196F3',
        swipeDirection: SwipeDirection.right,
        iconName: 'directions_car',
      ),
      Category(
        id: '3',
        name: 'Shopping',
        colorHex: 'E91E63',
        swipeDirection: SwipeDirection.down,
        iconName: 'shopping_bag',
      ),
      Category(
        id: '4',
        name: 'Entertainment',
        colorHex: '9C27B0',
        swipeDirection: SwipeDirection.left,
        iconName: 'movie',
      ),
      Category(
        id: '5',
        name: 'Bills',
        colorHex: 'FF9800',
        swipeDirection: SwipeDirection.up,
        iconName: 'receipt',
      ),
      Category(
        id: '6',
        name: 'Other',
        colorHex: '607D8B',
        swipeDirection: SwipeDirection.down,
        iconName: 'category',
      ),
    ];
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

/// Service for managing categories with local persistence
class CategoryService {
  static const String _categoriesKey = 'categories';
  static const String _swipeMappingsKey = 'swipe_mappings';

  /// Save categories to local storage
  Future<void> saveCategories(List<Category> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(categoriesJson);
      await prefs.setString(_categoriesKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save categories: $e');
    }
  }

  /// Load categories from local storage
  /// Returns default categories if none exist
  Future<List<Category>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_categoriesKey);

      if (jsonString == null || jsonString.isEmpty) {
        // Initialize with default categories if none exist
        final defaultCategories = Category.createDefaultCategories();
        await saveCategories(defaultCategories);
        return defaultCategories;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      // If there's any error loading, return default categories
      final defaultCategories = Category.createDefaultCategories();
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
  }

  /// Add a new category
  Future<void> addCategory(Category category) async {
    try {
      final categories = await loadCategories();
      categories.add(category);
      await saveCategories(categories);
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  /// Delete a category by ID
  Future<void> deleteCategory(String id) async {
    try {
      final categories = await loadCategories();
      categories.removeWhere((c) => c.id == id);
      await saveCategories(categories);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Clear all categories (for testing purposes)
  Future<void> clearCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_categoriesKey);
      await prefs.remove(_swipeMappingsKey);
    } catch (e) {
      throw Exception('Failed to clear categories: $e');
    }
  }

  /// Save swipe mappings to local storage
  Future<void> saveSwipeMappings(Map<SwipeDirection, String> mappings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappingsJson = <String, String>{};
      mappings.forEach((direction, categoryId) {
        mappingsJson[direction.toString().split('.').last] = categoryId;
      });
      final jsonString = jsonEncode(mappingsJson);
      await prefs.setString(_swipeMappingsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save swipe mappings: $e');
    }
  }

  /// Load swipe mappings from local storage
  /// Returns default mappings if none exist
  Future<Map<SwipeDirection, String>> loadSwipeMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_swipeMappingsKey);

      if (jsonString == null || jsonString.isEmpty) {
        // Initialize with default mappings if none exist
        final defaultMappings = await _getDefaultSwipeMappingsWithOtherCategory();
        await saveSwipeMappings(defaultMappings);
        return defaultMappings;
      }

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final mappings = <SwipeDirection, String>{};
      jsonMap.forEach((key, value) {
        final direction = SwipeDirection.values.firstWhere(
          (e) => e.toString().split('.').last == key,
        );
        mappings[direction] = value as String;
      });

      return mappings;
    } catch (e) {
      // If there's any error loading, return default mappings
      final defaultMappings = await _getDefaultSwipeMappingsWithOtherCategory();
      await saveSwipeMappings(defaultMappings);
      return defaultMappings;
    }
  }

  /// Get default swipe mappings with the actual "Other" category ID
  /// Now supports all 8 directions (4 main + 4 corner)
  Future<Map<SwipeDirection, String>> _getDefaultSwipeMappingsWithOtherCategory() async {
    final categories = await loadCategories();

    // Use the default swipe mappings from Category model
    final defaultMappings = Category.getDefaultSwipeMappings();

    // Map each SwipeDirection to the actual category ID from loaded categories
    final mappings = <SwipeDirection, String>{};

    defaultMappings.forEach((direction, defaultCategoryId) {
      // Find the category with this ID in the loaded categories
      try {
        final category = categories.firstWhere((c) => c.id == defaultCategoryId);
        mappings[direction] = category.id;
      } catch (e) {
        // If category not found, skip this mapping
        // This shouldn't happen with default categories, but prevents errors
      }
    });

    return mappings;
  }
}

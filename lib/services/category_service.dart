import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

/// Service for managing categories with local persistence
class CategoryService {
  static const String _categoriesKey = 'categories';

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
    } catch (e) {
      throw Exception('Failed to clear categories: $e');
    }
  }
}

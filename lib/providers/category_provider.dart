import 'package:flutter/foundation.dart';
import '../models/category.dart' as model;
import '../services/category_service.dart';

/// Provider for managing category state
class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  List<model.Category> _categories = [];
  final Map<model.SwipeDirection, String> _swipeMappings = {};
  bool _isLoading = false;

  CategoryProvider() {
    _loadCategories();
  }

  /// Get all categories
  List<model.Category> get categories => List.unmodifiable(_categories);

  /// Get swipe mappings
  Map<model.SwipeDirection, String> get swipeMappings =>
      Map.unmodifiable(_swipeMappings);

  /// Check if categories are loading
  bool get isLoading => _isLoading;

  /// Load categories from storage
  Future<void> _loadCategories() async {
    try {
      _isLoading = true;
      notifyListeners();

      _categories = await _categoryService.loadCategories();
      _swipeMappings.clear();
      _swipeMappings.addAll(await _categoryService.loadSwipeMappings());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new category
  Future<void> addCategory(model.Category category) async {
    try {
      await _categoryService.addCategory(category);
      _categories.add(category);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  /// Update an existing category
  Future<void> updateCategory(model.Category category) async {
    try {
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        await _categoryService.saveCategories(_categories);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      // Check if this category is the "Other" category
      final category = getCategoryById(id);
      if (category != null && category.name.toLowerCase() == 'other') {
        throw Exception('Cannot delete the Other category');
      }

      // Remove category from swipe mappings if it's mapped
      _swipeMappings.removeWhere((key, value) => value == id);
      await _categoryService.saveSwipeMappings(_swipeMappings);

      // Delete the category
      await _categoryService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  /// Get available swipe directions (ones not currently mapped)
  List<model.SwipeDirection> getAvailableDirections() {
    final usedDirections = _swipeMappings.keys.toSet();
    return model.SwipeDirection.values
        .where((d) => !usedDirections.contains(d))
        .toList();
  }

  /// Get categories that can be mapped to swipe directions (all categories)
  List<model.Category> getCategoriesForSwipeMapping() {
    return _categories;
  }

  /// Get "Other" category
  model.Category? getOtherCategory() {
    try {
      return _categories.firstWhere((c) => c.name.toLowerCase() == 'other');
    } catch (e) {
      return null;
    }
  }

  /// Map a swipe direction to a category
  /// All 8 directions can be freely mapped to any category
  Future<void> mapSwipeToCategory(
      model.SwipeDirection direction, String categoryId) async {
    try {
      // Update the mapping
      _swipeMappings[direction] = categoryId;
      await _categoryService.saveSwipeMappings(_swipeMappings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error mapping swipe to category: $e');
      rethrow;
    }
  }

  /// Unmap a swipe direction
  Future<void> unmapSwipeDirection(model.SwipeDirection direction) async {
    try {
      _swipeMappings.remove(direction);
      await _categoryService.saveSwipeMappings(_swipeMappings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error unmapping swipe direction: $e');
      rethrow;
    }
  }

  /// Get category for a swipe direction
  String? getCategoryForSwipe(model.SwipeDirection direction) {
    return _swipeMappings[direction];
  }

  /// Get category by ID
  model.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Reload categories from storage
  Future<void> reloadCategories() async {
    await _loadCategories();
  }

  /// Reset to default categories
  Future<void> resetToDefaults() async {
    try {
      await _categoryService.clearCategories();
      await _loadCategories();
    } catch (e) {
      debugPrint('Error resetting categories: $e');
      rethrow;
    }
  }
}

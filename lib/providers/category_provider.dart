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
      _updateSwipeMappings();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update swipe direction to category mappings
  void _updateSwipeMappings() {
    _swipeMappings.clear();
    for (final category in _categories) {
      _swipeMappings[category.swipeDirection] = category.id;
    }
  }

  /// Add a new category
  Future<void> addCategory(model.Category category) async {
    try {
      await _categoryService.addCategory(category);
      _categories.add(category);
      _updateSwipeMappings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      await _categoryService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _updateSwipeMappings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  /// Map a swipe direction to a category
  Future<void> mapSwipeToCategory(
      model.SwipeDirection direction, String categoryId) async {
    try {
      // Find the category
      final category = _categories.firstWhere((c) => c.id == categoryId);

      // Update the category's swipe direction
      final updatedCategory = model.Category(
        id: category.id,
        name: category.name,
        colorHex: category.colorHex,
        swipeDirection: direction,
        iconName: category.iconName,
      );

      // Remove old category and add updated one
      _categories.removeWhere((c) => c.id == categoryId);
      _categories.add(updatedCategory);

      // Save to storage
      await _categoryService.saveCategories(_categories);
      _updateSwipeMappings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error mapping swipe to category: $e');
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

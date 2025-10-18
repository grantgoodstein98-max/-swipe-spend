import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/transaction.dart';

/// Provider for managing budget state
class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgets = [];
  static const _uuid = Uuid();

  List<Budget> get budgets => List.unmodifiable(_budgets);

  BudgetProvider() {
    loadBudgets();
  }

  /// Load budgets from storage
  Future<void> loadBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetsString = prefs.getString('budgets');

      if (budgetsString != null && budgetsString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(budgetsString);
        _budgets = decoded.map((json) => Budget.fromJson(json)).toList();
        debugPrint('✅ Loaded ${_budgets.length} budgets');
      } else {
        _budgets = [];
        debugPrint('ℹ️ No saved budgets found');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading budgets: $e');
      _budgets = [];
      notifyListeners();
    }
  }

  /// Save budgets to storage
  Future<void> _saveBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetsJson = _budgets.map((b) => b.toJson()).toList();
      await prefs.setString('budgets', jsonEncode(budgetsJson));
      debugPrint('💾 Saved ${_budgets.length} budgets');
    } catch (e) {
      debugPrint('❌ Error saving budgets: $e');
      rethrow;
    }
  }

  /// Set or update budget for a category
  Future<void> setBudget(String categoryId, double limit) async {
    try {
      final existingIndex = _budgets.indexWhere((b) => b.categoryId == categoryId);

      if (existingIndex != -1) {
        // Update existing budget
        _budgets[existingIndex] = _budgets[existingIndex].copyWith(
          limit: limit,
          lastModified: DateTime.now(),
        );
        debugPrint('📝 Updated budget for category $categoryId: \$${limit.toStringAsFixed(2)}');
      } else {
        // Create new budget
        _budgets.add(Budget(
          id: _uuid.v4(),
          categoryId: categoryId,
          limit: limit,
          createdAt: DateTime.now(),
        ));
        debugPrint('➕ Created budget for category $categoryId: \$${limit.toStringAsFixed(2)}');
      }

      await _saveBudgets();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting budget: $e');
      rethrow;
    }
  }

  /// Get budget for a category
  Budget? getBudgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Delete budget for a category
  Future<void> deleteBudget(String categoryId) async {
    try {
      _budgets.removeWhere((b) => b.categoryId == categoryId);
      await _saveBudgets();
      notifyListeners();
      debugPrint('🗑️ Deleted budget for category $categoryId');
    } catch (e) {
      debugPrint('❌ Error deleting budget: $e');
      rethrow;
    }
  }

  /// Calculate spending for a category in current month
  double getSpendingForCategory(String categoryId, List<Transaction> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final spending = transactions
        .where((t) =>
            t.category == categoryId &&
            t.isCategorized &&
            t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            t.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    return spending;
  }

  /// Get budget status (percentage used)
  double getBudgetProgress(String categoryId, List<Transaction> transactions) {
    final budget = getBudgetForCategory(categoryId);
    if (budget == null || budget.limit == 0) return 0.0;

    final spending = getSpendingForCategory(categoryId, transactions);
    return (spending / budget.limit) * 100;
  }

  /// Check if over budget
  bool isOverBudget(String categoryId, List<Transaction> transactions) {
    return getBudgetProgress(categoryId, transactions) > 100;
  }

  /// Get total budget across all categories
  double get totalBudget {
    return _budgets.fold<double>(0.0, (sum, budget) => sum + budget.limit);
  }

  /// Get total spending across all budgets
  double getTotalSpending(List<Transaction> transactions) {
    double total = 0.0;
    for (final budget in _budgets) {
      total += getSpendingForCategory(budget.categoryId, transactions);
    }
    return total;
  }
}

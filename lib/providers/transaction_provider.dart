import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/plaid_service.dart';

/// Provider for managing transaction state
class TransactionProvider extends ChangeNotifier {
  final PlaidService _plaidService = PlaidService();
  List<Transaction> _transactions = [];

  TransactionProvider() {
    _loadTransactionsFromStorage();
  }

  /// Get all transactions
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  /// Get uncategorized transactions
  List<Transaction> get uncategorizedTransactions =>
      _transactions.where((t) => !t.isCategorized).toList();

  /// Get categorized transactions
  List<Transaction> get categorizedTransactions =>
      _transactions.where((t) => t.isCategorized).toList();

  /// Load transactions from SharedPreferences
  Future<void> _loadTransactionsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsString = prefs.getString('transactions');

      if (transactionsString != null && transactionsString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(transactionsString);
        _transactions = decoded.map((json) => Transaction.fromJson(json)).toList();
        debugPrint('✅ Loaded ${_transactions.length} transactions from storage');
      } else {
        debugPrint('ℹ️ No saved transactions found');
        _transactions = [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading transactions from storage: $e');
      _transactions = [];
      notifyListeners();
    }
  }

  /// Save transactions to SharedPreferences
  Future<void> _saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = _transactions.map((t) => t.toJson()).toList();
      await prefs.setString('transactions', jsonEncode(transactionsJson));
      debugPrint('✅ Saved ${_transactions.length} transactions to storage');
    } catch (e) {
      debugPrint('❌ Error saving transactions: $e');
      rethrow;
    }
  }

  /// Add a new transaction
  void addTransaction(Transaction transaction) {
    try {
      _transactions.add(transaction);
      // Sort by date (newest first)
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  /// Categorize a transaction
  Future<void> categorizeTransaction(String transactionId, String categoryId) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index].category = categoryId;
        _transactions[index].isCategorized = true;
        notifyListeners();
        await _saveTransactions();
      }
    } catch (e) {
      debugPrint('Error categorizing transaction: $e');
      rethrow;
    }
  }

  /// Recategorize a transaction (move from one category to another)
  Future<void> recategorizeTransaction(String transactionId, String newCategoryId) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index].category = newCategoryId;
        _transactions[index].isCategorized = true;
        notifyListeners();
        await _saveTransactions();
        debugPrint('✅ Recategorized transaction to category: $newCategoryId');
      }
    } catch (e) {
      debugPrint('Error recategorizing transaction: $e');
      rethrow;
    }
  }

  /// Uncategorize a transaction (undo)
  Future<void> uncategorizeTransaction(String transactionId) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index].category = null;
        _transactions[index].isCategorized = false;
        notifyListeners();
        await _saveTransactions();
      }
    } catch (e) {
      debugPrint('Error uncategorizing transaction: $e');
      rethrow;
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
      await _saveTransactions();
      debugPrint('✅ Deleted transaction: $transactionId');
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Get transactions by category
  List<Transaction> getTransactionsByCategory(String categoryId) {
    return _transactions
        .where((t) => t.category == categoryId && t.isCategorized)
        .toList();
  }

  /// Get total spending for a category
  double getTotalSpendingByCategory(String categoryId) {
    return getTransactionsByCategory(categoryId)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  /// Get total spending across all transactions
  double get totalSpending =>
      _transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);

  /// Get total categorized spending
  double get totalCategorizedSpending => categorizedTransactions.fold(
      0.0, (sum, transaction) => sum + transaction.amount);

  /// Load transactions from Plaid
  /// TODO: Implement when Plaid integration is ready
  Future<void> loadTransactions() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final fetchedTransactions =
          await _plaidService.fetchTransactions(
            startDate: thirtyDaysAgo,
            endDate: now,
          );

      _transactions = fetchedTransactions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions from Plaid: $e');
      // Don't load mock data - keep existing transactions or empty list
    }
  }

  /// Refresh transactions
  Future<void> refreshTransactions() async {
    await loadTransactions();
  }

  /// Clear all transactions (for testing)
  void clearTransactions() {
    _transactions.clear();
    notifyListeners();
  }

  /// Import transactions from a file with duplicate detection
  /// Returns the number of transactions actually imported (excluding duplicates)
  Future<int> importTransactions(List<Transaction> newTransactions) async {
    try {
      debugPrint('📥 Importing ${newTransactions.length} transactions...');
      int importedCount = 0;
      int duplicateCount = 0;

      for (final newTransaction in newTransactions) {
        // Check for duplicates based on name, amount, and date
        final isDuplicate = _transactions.any((existing) =>
            existing.name == newTransaction.name &&
            (existing.amount - newTransaction.amount).abs() < 0.01 &&
            existing.date.year == newTransaction.date.year &&
            existing.date.month == newTransaction.date.month &&
            existing.date.day == newTransaction.date.day);

        if (!isDuplicate) {
          _transactions.add(newTransaction);
          importedCount++;
        } else {
          duplicateCount++;
        }
      }

      debugPrint('✅ $importedCount unique transactions');
      debugPrint('⏭️ $duplicateCount duplicates skipped');

      // Sort by date (newest first) after import
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      if (importedCount > 0) {
        await _saveTransactions();
        notifyListeners();
      }

      debugPrint('🔍 Total transactions now: ${_transactions.length}');
      debugPrint('🔍 Uncategorized: ${uncategorizedTransactions.length}');

      return importedCount;
    } catch (e) {
      debugPrint('❌ Error importing transactions: $e');
      rethrow;
    }
  }
}

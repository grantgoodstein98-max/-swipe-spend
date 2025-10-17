import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/plaid_service.dart';

/// Provider for managing transaction state
class TransactionProvider extends ChangeNotifier {
  final PlaidService _plaidService = PlaidService();
  List<Transaction> _transactions = [];

  TransactionProvider() {
    _loadMockTransactions();
  }

  /// Get all transactions
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  /// Get uncategorized transactions
  List<Transaction> get uncategorizedTransactions =>
      _transactions.where((t) => !t.isCategorized).toList();

  /// Get categorized transactions
  List<Transaction> get categorizedTransactions =>
      _transactions.where((t) => t.isCategorized).toList();

  /// Load mock transactions for testing
  void _loadMockTransactions() {
    try {
      _transactions = _plaidService.generateMockTransactions(count: 15);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading mock transactions: $e');
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
  void categorizeTransaction(String transactionId, String categoryId) {
    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index].category = categoryId;
        _transactions[index].isCategorized = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error categorizing transaction: $e');
      rethrow;
    }
  }

  /// Uncategorize a transaction (undo)
  void uncategorizeTransaction(String transactionId) {
    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index].category = null;
        _transactions[index].isCategorized = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error uncategorizing transaction: $e');
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
          await _plaidService.fetchTransactions(thirtyDaysAgo, now);

      _transactions = fetchedTransactions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions from Plaid: $e');
      // Fall back to mock data on error
      _loadMockTransactions();
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
}

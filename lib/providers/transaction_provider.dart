import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/plaid_service.dart';

/// Provider for managing transaction state
class TransactionProvider extends ChangeNotifier {
  final PlaidService _plaidService = PlaidService();
  List<Transaction> _transactions = [];
  bool _isUsingDummyData = false;

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

      // Don't load from storage if using dummy data (check after async operations)
      if (_isUsingDummyData) {
        debugPrint('⏭️ Skipping storage load (using dummy data)');
        return;
      }

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
    _isUsingDummyData = false;
    notifyListeners();
  }

  /// Load dummy data for guest mode (does not persist to storage)
  void loadDummyData() {
    _isUsingDummyData = true;
    final now = DateTime.now();

    _transactions = [
      // Recent transactions (last 7 days)
      Transaction(
        id: 'guest_1',
        plaidId: 'plaid_guest_1',
        name: 'Starbucks',
        merchantName: 'Starbucks Coffee',
        amount: 5.67,
        date: now.subtract(const Duration(days: 1)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_2',
        plaidId: 'plaid_guest_2',
        name: 'Uber',
        merchantName: 'Uber Technologies',
        amount: 23.45,
        date: now.subtract(const Duration(days: 2)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_3',
        plaidId: 'plaid_guest_3',
        name: 'Whole Foods',
        merchantName: 'Whole Foods Market',
        amount: 87.32,
        date: now.subtract(const Duration(days: 3)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_4',
        plaidId: 'plaid_guest_4',
        name: 'Amazon',
        merchantName: 'Amazon.com',
        amount: 42.99,
        date: now.subtract(const Duration(days: 4)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_5',
        plaidId: 'plaid_guest_5',
        name: 'Netflix',
        merchantName: 'Netflix Inc',
        amount: 15.99,
        date: now.subtract(const Duration(days: 5)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_6',
        plaidId: 'plaid_guest_6',
        name: 'Shell Gas Station',
        merchantName: 'Shell',
        amount: 45.00,
        date: now.subtract(const Duration(days: 6)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_7',
        plaidId: 'plaid_guest_7',
        name: 'Chipotle',
        merchantName: 'Chipotle Mexican Grill',
        amount: 12.50,
        date: now.subtract(const Duration(days: 7)),
        isCategorized: false,
      ),
      // Mid-range transactions (8-20 days ago)
      Transaction(
        id: 'guest_8',
        plaidId: 'plaid_guest_8',
        name: 'Target',
        merchantName: 'Target Corporation',
        amount: 156.78,
        date: now.subtract(const Duration(days: 10)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_9',
        plaidId: 'plaid_guest_9',
        name: 'Spotify',
        merchantName: 'Spotify',
        amount: 10.99,
        date: now.subtract(const Duration(days: 12)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_10',
        plaidId: 'plaid_guest_10',
        name: 'McDonald\'s',
        merchantName: 'McDonald\'s',
        amount: 8.75,
        date: now.subtract(const Duration(days: 14)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_11',
        plaidId: 'plaid_guest_11',
        name: 'Costco',
        merchantName: 'Costco Wholesale',
        amount: 234.56,
        date: now.subtract(const Duration(days: 15)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_12',
        plaidId: 'plaid_guest_12',
        name: 'Planet Fitness',
        merchantName: 'Planet Fitness',
        amount: 10.00,
        date: now.subtract(const Duration(days: 18)),
        isCategorized: false,
      ),
      // Older transactions (21-30 days ago)
      Transaction(
        id: 'guest_13',
        plaidId: 'plaid_guest_13',
        name: 'AT&T',
        merchantName: 'AT&T Inc',
        amount: 85.00,
        date: now.subtract(const Duration(days: 22)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_14',
        plaidId: 'plaid_guest_14',
        name: 'CVS Pharmacy',
        merchantName: 'CVS',
        amount: 34.21,
        date: now.subtract(const Duration(days: 24)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_15',
        plaidId: 'plaid_guest_15',
        name: 'Apple Store',
        merchantName: 'Apple Inc',
        amount: 199.99,
        date: now.subtract(const Duration(days: 26)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_16',
        plaidId: 'plaid_guest_16',
        name: 'Panera Bread',
        merchantName: 'Panera Bread',
        amount: 14.32,
        date: now.subtract(const Duration(days: 28)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_17',
        plaidId: 'plaid_guest_17',
        name: 'Best Buy',
        merchantName: 'Best Buy',
        amount: 127.45,
        date: now.subtract(const Duration(days: 29)),
        isCategorized: false,
      ),
      Transaction(
        id: 'guest_18',
        plaidId: 'plaid_guest_18',
        name: 'Kroger',
        merchantName: 'Kroger',
        amount: 62.18,
        date: now.subtract(const Duration(days: 30)),
        isCategorized: false,
      ),
    ];

    // Sort by date (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    debugPrint('✅ Loaded ${_transactions.length} dummy transactions for guest mode');
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

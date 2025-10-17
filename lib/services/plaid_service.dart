import 'dart:math';
import '../models/transaction.dart';

/// Service for Plaid integration
/// TODO: Implement actual Plaid SDK integration
class PlaidService {
  bool _isInitialized = false;

  /// Initialize Plaid Link
  /// TODO: Implement Plaid initialization with API keys
  Future<void> initializePlaid() async {
    try {
      // Placeholder for Plaid initialization
      // In production, this would:
      // 1. Load Plaid API keys from secure storage
      // 2. Initialize Plaid Link Handler
      // 3. Set up webhook handlers
      await Future.delayed(const Duration(milliseconds: 500));
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Plaid: $e');
    }
  }

  /// Fetch transactions from Plaid
  /// TODO: Implement actual Plaid API calls
  Future<List<Transaction>> fetchTransactions(
      DateTime start, DateTime end) async {
    try {
      if (!_isInitialized) {
        await initializePlaid();
      }

      // Placeholder for actual Plaid transaction fetch
      // In production, this would:
      // 1. Call Plaid Transactions API
      // 2. Handle pagination
      // 3. Parse and normalize transaction data
      await Future.delayed(const Duration(seconds: 1));

      // Return empty list for now
      return [];
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Generate mock transactions for testing
  List<Transaction> generateMockTransactions({int count = 10}) {
    final random = Random();
    final merchants = [
      'Starbucks',
      'Walmart',
      'Amazon',
      'Shell Gas Station',
      'McDonald\'s',
      'Target',
      'Uber',
      'Netflix',
      'Whole Foods',
      'CVS Pharmacy',
      'Chipotle',
      'Home Depot',
      'Apple Store',
      'Best Buy',
      'Pizza Hut'
    ];

    final List<Transaction> transactions = [];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final merchantName = merchants[random.nextInt(merchants.length)];
      final amount = (random.nextDouble() * 100) + 5; // $5 - $105
      final daysAgo = random.nextInt(30); // Within last 30 days
      final date = now.subtract(Duration(days: daysAgo));

      transactions.add(Transaction(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}_$i',
        plaidId: 'plaid_mock_$i',
        name: merchantName,
        amount: double.parse(amount.toStringAsFixed(2)),
        date: date,
        merchantName: merchantName,
        category: null,
        isCategorized: false,
      ));
    }

    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  /// Check if Plaid is initialized
  bool get isInitialized => _isInitialized;
}

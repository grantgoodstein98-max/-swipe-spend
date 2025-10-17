import '../models/transaction.dart';

/// Helper functions for chart data calculations
class ChartHelper {
  /// Calculate total spending for a date range
  static double calculateTotalSpending(
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
  ) {
    final filtered = filterTransactionsByDateRange(transactions, start, end);
    return filtered.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  /// Get spending breakdown by category for a date range
  static Map<String, double> getSpendingByCategory(
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
  ) {
    final filtered = filterTransactionsByDateRange(transactions, start, end);
    final Map<String, double> categoryTotals = {};

    for (final transaction in filtered) {
      if (transaction.category != null && transaction.isCategorized) {
        categoryTotals[transaction.category!] =
            (categoryTotals[transaction.category!] ?? 0.0) + transaction.amount;
      }
    }

    return categoryTotals;
  }

  /// Get date range based on selection
  static Map<String, DateTime> getDateRangeFromSelection(String range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;

    switch (range) {
      case 'Day':
        start = today;
        break;
      case 'Month':
        start = today.subtract(const Duration(days: 30));
        break;
      case '3 Months':
        start = today.subtract(const Duration(days: 90));
        break;
      case 'Year':
        start = today.subtract(const Duration(days: 365));
        break;
      default:
        start = today.subtract(const Duration(days: 30));
    }

    return {'start': start, 'end': now};
  }

  /// Filter transactions by date range
  static List<Transaction> filterTransactionsByDateRange(
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions.where((transaction) {
      return transaction.date.isAfter(start.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calculate percentage of total
  static double calculatePercentage(double amount, double total) {
    if (total == 0) return 0.0;
    return (amount / total) * 100;
  }

  /// Get categorized transactions only
  static List<Transaction> getCategorizedTransactions(
    List<Transaction> transactions,
  ) {
    return transactions.where((t) => t.isCategorized).toList();
  }

  /// Sort category totals by amount (highest first)
  static List<MapEntry<String, double>> sortCategoryTotals(
    Map<String, double> categoryTotals,
  ) {
    final entries = categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Get transactions for a specific category in a date range
  static List<Transaction> getTransactionsForCategory(
    List<Transaction> transactions,
    String categoryId,
    DateTime start,
    DateTime end,
  ) {
    final filtered = filterTransactionsByDateRange(transactions, start, end);
    return filtered
        .where((t) => t.category == categoryId && t.isCategorized)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date (newest first)
  }
}

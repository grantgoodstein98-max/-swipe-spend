import '../models/transaction.dart';
import '../models/category.dart';

/// Utility class for analyzing spending patterns and generating reports for AI
class SpendingAnalyzer {
  /// Generate a comprehensive spending report for AI analysis
  static String generateSpendingReport(
    List<Transaction> transactions,
    List<Category> categories, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Default to last 30 days
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 30));

    // Filter transactions by date range
    final filteredTransactions = transactions.where((t) {
      return t.date.isAfter(start) && t.date.isBefore(end);
    }).toList();

    if (filteredTransactions.isEmpty) {
      return 'No transactions found in the specified date range.';
    }

    final buffer = StringBuffer();

    // Header
    buffer.writeln('SPENDING ANALYSIS REPORT');
    buffer.writeln('Period: ${_formatDate(start)} to ${_formatDate(end)}');
    buffer.writeln('');

    // Total spending
    final totalSpending = filteredTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    buffer.writeln('Total Spending: \$${totalSpending.toStringAsFixed(2)}');
    buffer.writeln('');

    // Spending by category
    buffer.writeln('SPENDING BY CATEGORY:');
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final transaction in filteredTransactions) {
      if (transaction.category != null) {
        categoryTotals[transaction.category!] =
            (categoryTotals[transaction.category!] ?? 0) + transaction.amount;
        categoryCounts[transaction.category!] =
            (categoryCounts[transaction.category!] ?? 0) + 1;
      }
    }

    // Sort by amount (highest first)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: entry.key,
          name: 'Unknown',
          colorHex: '000000',
          swipeDirection: SwipeDirection.up,
          iconName: 'help_outline',
        ),
      );
      final percentage = (entry.value / totalSpending * 100);
      final count = categoryCounts[entry.key] ?? 0;
      buffer.writeln(
        '  ${category.name}: \$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%) - $count transaction${count != 1 ? 's' : ''}',
      );
    }
    buffer.writeln('');

    // Average spending
    final days = end.difference(start).inDays;
    final avgDaily = totalSpending / days;
    final avgWeekly = avgDaily * 7;
    final avgMonthly = avgDaily * 30;
    buffer.writeln('AVERAGES:');
    buffer.writeln('  Daily: \$${avgDaily.toStringAsFixed(2)}');
    buffer.writeln('  Weekly: \$${avgWeekly.toStringAsFixed(2)}');
    buffer.writeln('  Monthly: \$${avgMonthly.toStringAsFixed(2)}');
    buffer.writeln('');

    // Highest transaction
    final highestTransaction = filteredTransactions.reduce(
      (a, b) => a.amount > b.amount ? a : b,
    );
    final highestCategory = categories.firstWhere(
      (c) => c.id == highestTransaction.category,
      orElse: () => Category(
        id: '',
        name: 'Uncategorized',
        colorHex: '000000',
        swipeDirection: SwipeDirection.up,
        iconName: 'help_outline',
      ),
    );
    buffer.writeln('NOTABLE TRANSACTIONS:');
    buffer.writeln(
      '  Highest: \$${highestTransaction.amount.toStringAsFixed(2)} at ${highestTransaction.merchantName ?? highestTransaction.name} (${highestCategory.name})',
    );
    buffer.writeln('');

    // Most frequent category
    if (categoryCounts.isNotEmpty) {
      final mostFrequent = categoryCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final category = categories.firstWhere(
        (c) => c.id == mostFrequent.key,
        orElse: () => Category(
          id: mostFrequent.key,
          name: 'Unknown',
          colorHex: '000000',
          swipeDirection: SwipeDirection.up,
          iconName: 'help_outline',
        ),
      );
      buffer.writeln('PATTERNS:');
      buffer.writeln(
        '  Most frequent category: ${category.name} (${mostFrequent.value} transactions)',
      );
    }

    // Uncategorized transactions
    final uncategorized = filteredTransactions.where((t) => t.category == null).length;
    if (uncategorized > 0) {
      buffer.writeln('  Uncategorized transactions: $uncategorized');
    }

    return buffer.toString();
  }

  /// Get quick stats for display
  static Map<String, dynamic> getQuickStats(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return {
        'total': 0.0,
        'count': 0,
        'avgTransaction': 0.0,
        'categorized': 0,
        'uncategorized': 0,
      };
    }

    final total = transactions.fold<double>(0, (sum, t) => sum + t.amount);
    final categorized = transactions.where((t) => t.category != null).length;
    final uncategorized = transactions.where((t) => t.category == null).length;

    return {
      'total': total,
      'count': transactions.length,
      'avgTransaction': total / transactions.length,
      'categorized': categorized,
      'uncategorized': uncategorized,
    };
  }

  /// Compare spending between two periods
  static String compareSpendingPeriods(
    List<Transaction> currentTransactions,
    List<Transaction> previousTransactions,
  ) {
    final currentTotal = currentTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final previousTotal = previousTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    if (previousTotal == 0) {
      return 'No previous data available for comparison.';
    }

    final difference = currentTotal - previousTotal;
    final percentChange = (difference / previousTotal * 100);

    if (difference > 0) {
      return 'Spending increased by \$${difference.toStringAsFixed(2)} (${percentChange.toStringAsFixed(1)}%) compared to previous period.';
    } else if (difference < 0) {
      return 'Spending decreased by \$${difference.abs().toStringAsFixed(2)} (${percentChange.abs().toStringAsFixed(1)}%) compared to previous period.';
    } else {
      return 'Spending remained the same compared to previous period.';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as model;
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/chart_helper.dart';

/// Screen showing detailed transactions for a specific category
class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;
  final DateTime startDate;
  final DateTime endDate;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, transactionProvider, categoryProvider, child) {
        final category = categoryProvider.getCategoryById(categoryId);

        if (category == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Category Not Found'),
            ),
            body: const Center(
              child: Text('Category not found'),
            ),
          );
        }

        // Get all transactions for this category in the date range
        final allTransactions = transactionProvider.transactions;
        final filteredTransactions = ChartHelper.filterTransactionsByDateRange(
          allTransactions,
          startDate,
          endDate,
        );

        final categoryTransactions = filteredTransactions
            .where((t) => t.category == categoryId && t.isCategorized)
            .toList();

        // Sort by date (newest first)
        categoryTransactions.sort((a, b) => b.date.compareTo(a.date));

        // Calculate total and percentage
        final categoryTotal = categoryTransactions.fold(
          0.0,
          (sum, transaction) => sum + transaction.amount,
        );
        final overallTotal = ChartHelper.calculateTotalSpending(
          ChartHelper.getCategorizedTransactions(allTransactions),
          startDate,
          endDate,
        );
        final percentage = ChartHelper.calculatePercentage(
          categoryTotal,
          overallTotal,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(category.name),
            backgroundColor: category.color,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              // Category summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: category.color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      category.icon,
                      size: 48,
                      color: category.color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${categoryTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: category.color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total spending',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${categoryTransactions.length} transaction${categoryTransactions.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              ),

              // Transactions list
              Expanded(
                child: categoryTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions in this category',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categoryTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = categoryTransactions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: category.color,
                                ),
                              ),
                              title: Text(
                                transaction.merchantName ?? transaction.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                transaction.formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Text(
                                transaction.formattedAmount,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: category.color,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

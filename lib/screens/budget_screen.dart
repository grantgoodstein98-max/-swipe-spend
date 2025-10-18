import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/category.dart' as model;
import '../models/budget.dart';
import '../models/transaction.dart';
import 'settings_screen.dart';

/// Screen for viewing and managing budgets
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Monthly Budget',
          style: theme.textTheme.displayLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer3<BudgetProvider, CategoryProvider, TransactionProvider>(
        builder: (context, budgetProvider, categoryProvider, transactionProvider, child) {
          final categories = categoryProvider.categories;
          final transactions = transactionProvider.transactions;

          // Calculate overall budget stats
          double totalBudget = 0;
          double totalSpent = 0;

          for (final category in categories) {
            final budget = budgetProvider.getBudgetForCategory(category.id);
            if (budget != null) {
              totalBudget += budget.limit;
              totalSpent += budgetProvider.getSpendingForCategory(category.id, transactions);
            }
          }

          final overallProgress = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;
          final hasAnyBudgets = categories.any((c) => budgetProvider.getBudgetForCategory(c.id) != null);

          return RefreshIndicator(
            onRefresh: () async {
              await transactionProvider.refreshTransactions();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall budget summary card
                  if (hasAnyBudgets)
                    _buildOverallSummaryCard(
                      context,
                      totalSpent,
                      totalBudget,
                      overallProgress,
                      isDark,
                    ),

                  // Section header
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, hasAnyBudgets ? 8 : 24, 16, 8),
                    child: Text(
                      'CATEGORY BUDGETS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Empty state message (only when no budgets)
                  if (!hasAnyBudgets)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'Tap any category to set a monthly spending limit',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),

                  // Category list (always show)
                  _buildCategoryList(
                    context,
                    categories,
                    budgetProvider,
                    transactions,
                    isDark,
                    theme,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallSummaryCard(
    BuildContext context,
    double totalSpent,
    double totalBudget,
    double overallProgress,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: overallProgress > 100
              ? [const Color(0xFFFF3B30), const Color(0xFFFF6B6B)]
              : overallProgress > 80
                  ? [const Color(0xFFFF9500), const Color(0xFFFFCC00)]
                  : [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${totalSpent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of \$${totalBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${overallProgress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (overallProgress / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Budgets Set',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap any category below to set a monthly spending limit',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<model.Category> categories,
    BudgetProvider budgetProvider,
    List<Transaction> transactions,
    bool isDark,
    ThemeData theme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final budget = budgetProvider.getBudgetForCategory(category.id);
        final spending = budgetProvider.getSpendingForCategory(category.id, transactions);
        final progress = budget != null && budget.limit > 0
            ? (spending / budget.limit) * 100
            : 0.0;
        final isOverBudget = progress > 100;

        return _buildCategoryBudgetCard(
          context,
          category,
          budget,
          spending,
          progress,
          isOverBudget,
          isDark,
          theme,
        );
      },
    );
  }

  Widget _buildCategoryBudgetCard(
    BuildContext context,
    model.Category category,
    Budget? budget,
    double spending,
    double progress,
    bool isOverBudget,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(
                color: const Color(0xFF38383A).withOpacity(0.5),
                width: 0.5,
              )
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBudgetDialog(context, category, budget),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Category name and budget info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            budget != null
                                ? '\$${spending.toStringAsFixed(2)} of \$${budget.limit.toStringAsFixed(2)}'
                                : 'No budget set',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    // Progress percentage
                    if (budget != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOverBudget
                              ? const Color(0xFFFF3B30).withOpacity(0.15)
                              : progress > 80
                                  ? const Color(0xFFFF9500).withOpacity(0.15)
                                  : const Color(0xFF34C759).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOverBudget
                                ? const Color(0xFFFF3B30)
                                : progress > 80
                                    ? const Color(0xFFFF9500)
                                    : const Color(0xFF34C759),
                          ),
                        ),
                      ),
                  ],
                ),

                // Progress bar
                if (budget != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget
                            ? const Color(0xFFFF3B30)
                            : progress > 80
                                ? const Color(0xFFFF9500)
                                : category.color,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    model.Category category,
    Budget? existingBudget,
  ) {
    final controller = TextEditingController(
      text: existingBudget?.limit.toStringAsFixed(0) ?? '',
    );
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Set Budget for ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly spending limit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
              ),
              onSubmitted: (value) {
                final amount = double.tryParse(value);
                if (amount != null && amount > 0) {
                  Provider.of<BudgetProvider>(context, listen: false)
                      .setBudget(category.id, amount);
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
        actions: [
          if (existingBudget != null)
            TextButton(
              onPressed: () {
                Provider.of<BudgetProvider>(context, listen: false)
                    .deleteBudget(category.id);
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Color(0xFFFF3B30)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Provider.of<BudgetProvider>(context, listen: false)
                    .setBudget(category.id, amount);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

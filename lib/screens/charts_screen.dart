import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart' as model;
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/chart_helper.dart';
import '../utils/color_helper.dart';

/// Screen for viewing spending charts and analytics
class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with TickerProviderStateMixin {
  String _selectedRange = 'Month';
  final List<String> _dateRanges = ['Day', 'Month', '3 Months', 'Year'];
  int _touchedIndex = -1;
  String? _touchedCategoryId;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  final Map<String, bool> _expandedCategories = {};
  String? _highlightedCategoryId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryId) {
    final key = _categoryKeys[categoryId];
    if (key?.currentContext != null) {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Highlight the category briefly
      setState(() {
        _highlightedCategoryId = categoryId;
      });

      // Scroll to the category
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );

      // Remove highlight after animation
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _highlightedCategoryId = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spending',
          style: theme.textTheme.displayLarge,
        ),
      ),
      body: Consumer3<TransactionProvider, CategoryProvider, ThemeProvider>(
        builder: (context, transactionProvider, categoryProvider, themeProvider, child) {
          // Get date range
          final dateRange = ChartHelper.getDateRangeFromSelection(_selectedRange);
          final startDate = dateRange['start']!;
          final endDate = dateRange['end']!;

          // Get categorized transactions only
          final allTransactions = transactionProvider.transactions;
          final categorizedTransactions =
              ChartHelper.getCategorizedTransactions(allTransactions);

          // Calculate totals
          final totalSpending = ChartHelper.calculateTotalSpending(
            categorizedTransactions,
            startDate,
            endDate,
          );

          final categoryTotals = ChartHelper.getSpendingByCategory(
            categorizedTransactions,
            startDate,
            endDate,
          );

          final sortedCategories = ChartHelper.sortCategoryTotals(categoryTotals);

          // Initialize category keys and expanded state (expanded by default)
          for (final entry in sortedCategories) {
            _categoryKeys.putIfAbsent(entry.key, () => GlobalKey());
            _expandedCategories.putIfAbsent(entry.key, () => true);
          }

          // Check if we have data
          final hasData = categorizedTransactions.isNotEmpty &&
              categoryTotals.isNotEmpty &&
              totalSpending > 0;

          return RefreshIndicator(
            onRefresh: () async {
              await transactionProvider.refreshTransactions();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Date range selector
                  _buildDateRangeSelector(),

                  const SizedBox(height: 24),

                  // Content
                  if (!hasData)
                    _buildEmptyState()
                  else
                    Column(
                      children: [
                        // Total spending display
                        _buildTotalSpending(totalSpending),

                        const SizedBox(height: 32),

                        // Pie chart with tooltip
                        _buildPieChartWithTooltip(
                          categoryTotals,
                          sortedCategories,
                          categoryProvider,
                          themeProvider,
                          totalSpending,
                          startDate,
                          endDate,
                          allTransactions,
                        ),

                        const SizedBox(height: 32),

                        // Category breakdown list
                        _buildCategoryBreakdown(
                          sortedCategories,
                          categoryProvider,
                          themeProvider,
                          totalSpending,
                          startDate,
                          endDate,
                          allTransactions,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _dateRanges.map((range) {
          final isSelected = range == _selectedRange;
          final index = _dateRanges.indexOf(range);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedRange = range;
                  _touchedIndex = -1;
                  _touchedCategoryId = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    range,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalSpending(double total) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Total Spending',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '\$${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
            color: theme.colorScheme.primary,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartWithTooltip(
    Map<String, double> categoryTotals,
    List<MapEntry<String, double>> sortedCategories,
    CategoryProvider categoryProvider,
    ThemeProvider themeProvider,
    double totalSpending,
    DateTime startDate,
    DateTime endDate,
    List<Transaction> allTransactions,
  ) {
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _buildPieChartSections(
                sortedCategories,
                categoryProvider,
                themeProvider,
                totalSpending,
              ),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      _touchedCategoryId = null;
                      return;
                    }

                    final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    _touchedIndex = index;

                    if (index >= 0 && index < sortedCategories.length) {
                      _touchedCategoryId = sortedCategories[index].key;

                      // If it's a tap (not hold), scroll to category
                      if (event is FlTapUpEvent) {
                        _scrollToCategory(_touchedCategoryId!);
                      } else {
                        // Haptic feedback for touch and hold
                        HapticFeedback.lightImpact();
                      }
                    }
                  });
                },
                enabled: true,
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),

        // Tooltip overlay
        if (_touchedIndex >= 0 && _touchedCategoryId != null)
          _buildTooltip(
            sortedCategories[_touchedIndex],
            categoryProvider,
            totalSpending,
          ),
      ],
    );
  }

  Widget _buildTooltip(
    MapEntry<String, double> entry,
    CategoryProvider categoryProvider,
    double totalSpending,
  ) {
    final category = categoryProvider.getCategoryById(entry.key);
    if (category == null) return const SizedBox.shrink();

    final percentage = ChartHelper.calculatePercentage(entry.value, totalSpending);

    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black87
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      color: category.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, double>> sortedCategories,
    CategoryProvider categoryProvider,
    ThemeProvider themeProvider,
    double totalSpending,
  ) {
    return List.generate(sortedCategories.length, (index) {
      final entry = sortedCategories[index];
      final category = categoryProvider.getCategoryById(entry.key);
      if (category == null) return PieChartSectionData(value: 0);

      final isTouched = index == _touchedIndex;
      final percentage = ChartHelper.calculatePercentage(
        entry.value,
        totalSpending,
      );

      // Adjust color for dark mode
      final color = ColorHelper.adjustColorForTheme(
        category.color,
        themeProvider.isDarkMode,
      );

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 110 : 100,
        titleStyle: TextStyle(
          fontSize: isTouched ? 18 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryBreakdown(
    List<MapEntry<String, double>> sortedCategories,
    CategoryProvider categoryProvider,
    ThemeProvider themeProvider,
    double totalSpending,
    DateTime startDate,
    DateTime endDate,
    List<Transaction> allTransactions,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Breakdown by Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...sortedCategories.map((entry) {
            final category = categoryProvider.getCategoryById(entry.key);
            if (category == null) return const SizedBox.shrink();

            return _buildCategorySection(
              entry,
              category,
              themeProvider,
              totalSpending,
              startDate,
              endDate,
              allTransactions,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    MapEntry<String, double> entry,
    model.Category category,
    ThemeProvider themeProvider,
    double totalSpending,
    DateTime startDate,
    DateTime endDate,
    List<Transaction> allTransactions,
  ) {
    final percentage = ChartHelper.calculatePercentage(entry.value, totalSpending);
    final isExpanded = _expandedCategories[entry.key] ?? false;
    final isHighlighted = _highlightedCategoryId == entry.key;
    final color = ColorHelper.adjustColorForTheme(category.color, themeProvider.isDarkMode);

    // Get transactions for this category
    final transactions = ChartHelper.getTransactionsForCategory(
      allTransactions,
      entry.key,
      startDate,
      endDate,
    );

    return Card(
      key: _categoryKeys[entry.key],
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isHighlighted ? 8 : 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expandedCategories[entry.key] = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Color indicator
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Category icon
                        Icon(
                          category.icon,
                          color: color,
                          size: 28,
                        ),
                        const SizedBox(width: 12),

                        // Category name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${transactions.length} transaction${transactions.length != 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        // Amount and percentage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${entry.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),

                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.expand_more,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),

                    // Percentage bar
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: color.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable transactions list
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      children: [
                        const Divider(height: 1),
                        ...transactions.map((transaction) {
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.store,
                              size: 20,
                              color: color.withOpacity(0.7),
                            ),
                            title: Text(
                              transaction.merchantName ?? transaction.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              transaction.formattedDate,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              transaction.formattedAmount,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Categorize transactions to see your spending breakdown',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to swipe screen
              DefaultTabController.of(context).animateTo(0);
            },
            icon: const Icon(Icons.swipe),
            label: const Text('Start Categorizing'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

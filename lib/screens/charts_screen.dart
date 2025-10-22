import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/category.dart' as model;
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/chart_helper.dart';
import '../utils/color_helper.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

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
  bool _showPieChart = true;
  bool _showCategoryBreakdown = false;
  bool _showMonthlyTrends = false;
  Set<dynamic> _selectedTrendCategories = {};
  bool _hasInitializedFilter = false;

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

                        // Pie chart with tooltip (collapsible)
                        _buildPieChartSection(
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

                        const SizedBox(height: 16),

                        // Monthly trends collapsible section
                        _buildMonthlyTrendsSection(
                          allTransactions,
                          categoryProvider.categories,
                          themeProvider,
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

  Widget _buildPieChartSection(
    Map<String, double> categoryTotals,
    List<MapEntry<String, double>> sortedCategories,
    CategoryProvider categoryProvider,
    ThemeProvider themeProvider,
    double totalSpending,
    DateTime startDate,
    DateTime endDate,
    List<Transaction> allTransactions,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showPieChart = !_showPieChart;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category Distribution',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showPieChart ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showPieChart
                ? Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildPieChartWithTooltip(
                          categoryTotals,
                          sortedCategories,
                          categoryProvider,
                          themeProvider,
                          totalSpending,
                          startDate,
                          endDate,
                          allTransactions,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
          height: MediaQuery.of(context).size.height * 0.5, // Increased from 0.4 to 0.5
          child: PieChart(
            PieChartData(
              sectionsSpace: 3, // Increased spacing between slices
              centerSpaceRadius: 50, // Increased center space
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
    // Calculate positions for small slice badges to avoid overlap
    final smallSliceAngles = <int, double>{};
    double cumulativeAngle = 0;

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = ChartHelper.calculatePercentage(entry.value, totalSpending);
      final sliceAngle = (percentage / 100) * 360;

      if (percentage < 1.0) {
        smallSliceAngles[i] = cumulativeAngle + (sliceAngle / 2);
      }
      cumulativeAngle += sliceAngle;
    }

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

      // For slices under 1%, show label outside with a badge
      final isSmallSlice = percentage < 1.0;

      // Make small slices slightly bigger radius to be more clickable
      final baseRadius = isSmallSlice ? 105.0 : 100.0;
      final touchRadius = isTouched ? baseRadius + 10.0 : baseRadius;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: isSmallSlice ? '' : '${percentage.toStringAsFixed(1)}%',
        radius: touchRadius,
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
        // Show badge outside for small slices with smart positioning
        badgeWidget: isSmallSlice
            ? GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _touchedIndex = index;
                    _touchedCategoryId = entry.key;
                  });
                  _scrollToCategory(entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : null,
        // Use calculated position to reduce overlap
        badgePositionPercentageOffset: isSmallSlice ? 1.4 : 0.98,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showCategoryBreakdown = !_showCategoryBreakdown;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Breakdown by Category',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showCategoryBreakdown ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showCategoryBreakdown
                ? Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: sortedCategories.map((entry) {
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
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
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
              // Navigate to swipe screen (tab index 0)
              HomeScreen.switchTab(context, 0);
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

  // Monthly trends section wrapper
  Widget _buildMonthlyTrendsSection(
    List<Transaction> transactions,
    List<model.Category> categories,
    ThemeProvider themeProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showMonthlyTrends = !_showMonthlyTrends;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Monthly Trends',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_showMonthlyTrends)
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showCategoryFilterDialog(context);
                      },
                      tooltip: 'Filter Categories',
                    ),
                  AnimatedRotation(
                    turns: _showMonthlyTrends ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showMonthlyTrends
                ? Column(
                    children: [
                      const Divider(height: 1),
                      _buildMonthlyTrendsChart(
                        transactions,
                        categories,
                        themeProvider,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Monthly trends chart methods
  Widget _buildMonthlyTrendsChart(
    List<Transaction> transactions,
    List<model.Category> categories,
    ThemeProvider themeProvider,
  ) {
    final monthlyData = _calculateMonthlySpending(transactions, categories);

    if (monthlyData.isEmpty || !monthlyData.values.any((m) => m.isNotEmpty)) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No spending data available for the last 6 months',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 6 Months',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Spending by category (stacked)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              key: ValueKey(_selectedTrendCategories.toString()),
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxMonthlySpending(monthlyData, categories),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final monthNames = monthlyData.keys.toList();
                      final month = monthNames[group.x.toInt()];
                      return BarTooltipItem(
                        '$month\n\$${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final monthNames = monthlyData.keys.toList();
                        if (value.toInt() >= monthNames.length) return const Text('');

                        final month = monthNames[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            month,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _createBarGroups(monthlyData, categories, themeProvider),
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildChartLegend(monthlyData, categories, themeProvider),
        ],
      ),
    );
  }

  Map<String, Map<String, double>> _calculateMonthlySpending(
    List<Transaction> transactions,
    List<model.Category> categories,
  ) {
    final Map<String, Map<String, double>> monthlyData = {};
    final now = DateTime.now();

    // Get last 6 months
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM').format(monthDate);
      monthlyData[monthKey] = {};
    }

    // Group transactions by month and category
    for (var transaction in transactions) {
      if (!transaction.isCategorized || transaction.category == null) continue;

      final monthKey = DateFormat('MMM').format(transaction.date);

      // Only include if in last 6 months
      if (!monthlyData.containsKey(monthKey)) continue;

      final categoryId = transaction.category!;
      monthlyData[monthKey]![categoryId] =
          (monthlyData[monthKey]![categoryId] ?? 0) + transaction.amount;
    }

    return monthlyData;
  }

  List<BarChartGroupData> _createBarGroups(
    Map<String, Map<String, double>> monthlyData,
    List<model.Category> categories,
    ThemeProvider themeProvider,
  ) {
    final List<BarChartGroupData> groups = [];

    // Get top 5 categories by total spending
    final categoryTotals = <String, double>{};
    for (var monthData in monthlyData.values) {
      for (var entry in monthData.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    print('📊 Building bar groups:');
    print('   All categories: ${categoryTotals.keys.toList()}');
    print('   Selected categories: ${_selectedTrendCategories.toList()}');

    // Filter by selected categories (or empty if none selected)
    final filteredCategoryTotals = _selectedTrendCategories.isEmpty
      ? <String, double>{}  // Empty if no categories selected
      : Map.fromEntries(
          categoryTotals.entries.where((e) => _selectedTrendCategories.contains(e.key))
        );

    print('   Filtered categories: ${filteredCategoryTotals.keys.toList()}');

    final topCategories = filteredCategoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategoryIds = topCategories
        .take(5)
        .map((e) => e.key)
        .toList();

    // Create stacked bar for each month
    int monthIndex = 0;
    for (var entry in monthlyData.entries) {
      final monthData = entry.value;

      // Filter monthData to only include selected categories
      final filteredMonthData = Map<String, double>.fromEntries(
        monthData.entries.where((e) => topCategoryIds.contains(e.key))
      );

      // Only sum values for selected categories (topCategoryIds)
      final filteredTotal = topCategoryIds.fold<double>(
        0.0,
        (sum, categoryId) => sum + (filteredMonthData[categoryId] ?? 0),
      );

      groups.add(
        BarChartGroupData(
          x: monthIndex,
          barRods: [
            BarChartRodData(
              toY: filteredTotal,
              rodStackItems: _createStackItems(filteredMonthData, categories, topCategoryIds, themeProvider),
              borderRadius: BorderRadius.circular(4),
              width: 30,
            ),
          ],
        ),
      );

      monthIndex++;
    }

    return groups;
  }

  List<BarChartRodStackItem> _createStackItems(
    Map<String, double> monthData,
    List<model.Category> categories,
    List<String> topCategoryIds,
    ThemeProvider themeProvider,
  ) {
    final items = <BarChartRodStackItem>[];
    double currentY = 0;

    print('🔍 Creating stack items:');
    print('   topCategoryIds: $topCategoryIds');
    print('   monthData keys: ${monthData.keys.toList()}');

    for (var categoryId in topCategoryIds) {
      final amount = monthData[categoryId] ?? 0;
      if (amount == 0) continue;

      // Find category, skip if not found
      final category = categories.cast<model.Category?>().firstWhere(
        (c) => c?.id == categoryId,
        orElse: () => null,
      );

      if (category == null) {
        print('   ⚠️ Category not found: $categoryId');
        continue;
      }

      final color = ColorHelper.adjustColorForTheme(category.color, themeProvider.isDarkMode);

      print('   ✅ Adding stack: ${category.name} (\$${amount.toStringAsFixed(2)}) - Color: $color');

      items.add(
        BarChartRodStackItem(
          currentY,
          currentY + amount,
          color,
        ),
      );

      currentY += amount;
    }

    print('   Total items: ${items.length}');
    return items;
  }

  double _getMaxMonthlySpending(
    Map<String, Map<String, double>> monthlyData,
    List<model.Category> categories,
  ) {
    double max = 0;

    // Get category totals for filtering
    final categoryTotals = <String, double>{};
    for (var monthData in monthlyData.values) {
      for (var entry in monthData.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    // Filter by selected categories (or empty if none selected)
    final filteredCategoryTotals = _selectedTrendCategories.isEmpty
      ? <String, double>{}  // Empty if no categories selected
      : Map.fromEntries(
          categoryTotals.entries.where((e) => _selectedTrendCategories.contains(e.key))
        );

    final topCategories = filteredCategoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategoryIds = topCategories
        .take(5)
        .map((e) => e.key)
        .toList();

    // Calculate max only for selected categories
    for (var monthData in monthlyData.values) {
      final monthTotal = topCategoryIds.fold<double>(
        0,
        (sum, categoryId) => sum + (monthData[categoryId] ?? 0),
      );
      if (monthTotal > max) max = monthTotal;
    }

    // Round up to nearest 500
    return ((max / 500).ceil() * 500).toDouble();
  }

  Widget _buildChartLegend(
    Map<String, Map<String, double>> monthlyData,
    List<model.Category> categories,
    ThemeProvider themeProvider,
  ) {
    // Get top 5 categories
    final categoryTotals = <String, double>{};
    for (var monthData in monthlyData.values) {
      for (var entry in monthData.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    // Filter by selected categories
    final filteredCategoryTotals = Map.fromEntries(
      categoryTotals.entries.where((e) => _selectedTrendCategories.contains(e.key))
    );

    final topCategories = filteredCategoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: topCategories.take(5).map((entry) {
        final category = categories.firstWhere((c) => c.id == entry.key);
        final color = ColorHelper.adjustColorForTheme(category.color, themeProvider.isDarkMode);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showCategoryFilterDialog(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Get all categories that have transactions
    final transactions = transactionProvider.transactions;
    final categoriesWithData = <dynamic>{};
    for (var transaction in transactions) {
      if (transaction.isCategorized && transaction.category != null) {
        categoriesWithData.add(transaction.category!);
      }
    }

    print('🎯 Dialog categories: $categoriesWithData');
    print('🎯 Selected categories: $_selectedTrendCategories');

    // Initialize selected categories with all categories only on first use
    if (!_hasInitializedFilter) {
      _selectedTrendCategories = Set.from(categoriesWithData);
      _hasInitializedFilter = true;
      print('🎯 First time: Initialized to all categories');
    }

    // Note: If user has explicitly cleared all, _selectedTrendCategories will be empty
    // but we won't auto-fill it again because _hasInitializedFilter is now true

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Categories'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedTrendCategories = Set.from(categoriesWithData);
                            });
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedTrendCategories.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: categoriesWithData.map((categoryId) {
                          final category = categoryProvider.getCategoryById(categoryId);
                          if (category == null) return const SizedBox.shrink();

                          final color = ColorHelper.adjustColorForTheme(
                            category.color,
                            themeProvider.isDarkMode,
                          );
                          final isSelected = _selectedTrendCategories.contains(categoryId);

                          return CheckboxListTile(
                            title: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  color: color,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(category.name),
                              ],
                            ),
                            value: isSelected,
                            activeColor: color,
                            onChanged: (bool? value) {
                              HapticFeedback.selectionClick();
                              setDialogState(() {
                                if (value == true) {
                                  _selectedTrendCategories.add(categoryId);
                                } else {
                                  _selectedTrendCategories.remove(categoryId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('✅ Apply clicked! Selected: $_selectedTrendCategories');
                    // Allow empty selection (will show blank chart)
                    setState(() {
                      // Trigger rebuild with new filter
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

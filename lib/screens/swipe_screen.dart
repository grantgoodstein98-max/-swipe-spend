import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as model;
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/transaction_card.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'other_refinement_screen.dart';

/// Screen for swiping to categorize transactions
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final ScrollController _categoryScrollController = ScrollController();
  bool _showCategorizedList = false;
  int _currentCardIndex = 0;
  bool _showMotivationalHeader = true;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  double _lastHorizontalOffset = 0.0;
  double _lastVerticalOffset = 0.0;
  // Track peak offsets in each direction to preserve diagonal intent
  double _peakHorizontalOffset = 0.0;
  double _peakVerticalOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _categoryScrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtons();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!mounted) return;
    if (!_categoryScrollController.hasClients) return;

    setState(() {
      _canScrollLeft = _categoryScrollController.offset > 0;
      _canScrollRight = _categoryScrollController.offset <
                        _categoryScrollController.position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    // Scroll by 5 chips: (60px width + 8px margin) * 5 = 340px
    _categoryScrollController.animateTo(
      _categoryScrollController.offset - 340,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    // Scroll by 5 chips: (60px width + 8px margin) * 5 = 340px
    _categoryScrollController.animateTo(
      _categoryScrollController.offset + 340,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Swipe',
          style: theme.textTheme.displayLarge,
        ),
        actions: [
          // Settings button to configure swipe mappings
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              final uncategorizedCount =
                  transactionProvider.uncategorizedTransactions.length;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$uncategorizedCount left',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
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
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, transactionProvider, categoryProvider, child) {
          final uncategorizedTransactions =
              transactionProvider.uncategorizedTransactions;
          final categorizedTransactions =
              transactionProvider.categorizedTransactions;
          final categories = categoryProvider.categories;

          // Build category totals map
          final categoryTotals = <String, double>{};
          for (final category in categories) {
            categoryTotals[category.id] =
                transactionProvider.getTotalSpendingByCategory(category.id);
          }

          // Count active categories (with transactions)
          final activeCategoryCount = categoryTotals.values.where((total) => total > 0).length;

          // Show loading if categories are loading
          if (categoryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Calculate stats
          final now = DateTime.now();
          final todayCategorized = categorizedTransactions.where((t) {
            return t.date.year == now.year &&
                   t.date.month == now.month &&
                   t.date.day == now.day;
          }).length;

          final totalTransactions = transactionProvider.transactions.length;
          final progress = totalTransactions > 0
              ? categorizedTransactions.length / totalTransactions
              : 0.0;

          return Column(
            children: [
              // Motivational Header
              if (uncategorizedTransactions.isNotEmpty && _showMotivationalHeader)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Let\'s organize your spending! 💸',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${uncategorizedTransactions.length} transaction${uncategorizedTransactions.length != 1 ? 's' : ''} waiting',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${uncategorizedTransactions.length} left',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showMotivationalHeader = false;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% complete',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

              // Category Chips Section
              if (categorizedTransactions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: theme.brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                    border: theme.brightness == Brightness.dark
                        ? Border.all(
                            color: const Color(0xFF38383A).withOpacity(0.5),
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categorized',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🔥 3',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⚡ $todayCategorized',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showCategorizedList = !_showCategorizedList;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${categorizedTransactions.length} items',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _showCategorizedList
                                            ? Icons.expand_less
                                            : Icons.chevron_right,
                                        size: 16,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          // Update scroll buttons after this frame is built
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _updateScrollButtons();
                          });
                          return Row(
                            children: [
                          // Show left arrow if there are more than 5 categories total
                          if (categories.length > 5)
                            InkWell(
                              onTap: _canScrollLeft ? _scrollLeft : null,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(_canScrollLeft ? 0.1 : 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 20,
                                  color: theme.colorScheme.primary.withOpacity(_canScrollLeft ? 1.0 : 0.3),
                                ),
                              ),
                            ),
                          if (categories.length > 5) const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ListView.builder(
                                controller: _categoryScrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: categoryTotals.keys.length,
                                itemBuilder: (context, index) {
                                  final categoryId = categoryTotals.keys.elementAt(index);
                                  final total = categoryTotals[categoryId] ?? 0;
                                  final category = categories.firstWhere((c) => c.id == categoryId);

                                  // Show all categories, even with $0
                                  return Container(
                                    width: 60,
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          category.color.withOpacity(0.15),
                                          category.color.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: category.color.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          category.icon,
                                          color: category.color,
                                          size: 14,
                                        ),
                                        Text(
                                          '\$${total.toStringAsFixed(0)}',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: category.color,
                                            fontSize: 10,
                                            height: 1.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          category.name,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontSize: 7,
                                            height: 1.0,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (categories.length > 5) const SizedBox(width: 8),
                          // Show right arrow if there are more than 5 categories total
                          if (categories.length > 5)
                            InkWell(
                              onTap: _canScrollRight ? _scrollRight : null,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(_canScrollRight ? 0.1 : 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: theme.colorScheme.primary.withOpacity(_canScrollRight ? 1.0 : 0.3),
                                ),
                              ),
                            ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

              // Categorized transactions list (expandable)
              if (categorizedTransactions.isNotEmpty && _showCategorizedList)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: theme.brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                    border: theme.brightness == Brightness.dark
                        ? Border.all(
                            color: const Color(0xFF38383A).withOpacity(0.5),
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showCategorizedList = !_showCategorizedList;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Categorized',
                                style: theme.textTheme.headlineMedium,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${categorizedTransactions.length}',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _showCategorizedList
                                        ? Icons.chevron_right
                                        : Icons.chevron_right,
                                    size: 20,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showCategorizedList) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: categorizedTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = categorizedTransactions[index];
                              final category = categoryProvider
                                  .getCategoryById(transaction.category ?? '');
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    category?.icon ?? Icons.help_outline,
                                    color: category?.color,
                                  ),
                                  title: Text(transaction.name),
                                  subtitle: Text(category?.name ?? 'Unknown'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        transaction.formattedAmount,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.undo, size: 20),
                                        onPressed: () {
                                          transactionProvider
                                              .uncategorizeTransaction(transaction.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${transaction.name} moved back to uncategorized',
                                              ),
                                              duration: const Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        tooltip: 'Undo',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Swipe area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                        // Calculate card size - use most of the available space
                        final availableHeight = constraints.maxHeight;
                        final availableWidth = constraints.maxWidth;
                        final screenWidth = MediaQuery.of(context).size.width;

                        // Responsive sizing based on screen width
                        // Mobile: <= 600px, Tablet: 600-900px, Desktop: > 900px
                        final bool isMobile = screenWidth <= 600;
                        final bool isTablet = screenWidth > 600 && screenWidth <= 900;
                        final bool isDesktop = screenWidth > 900;

                        // Calculate card dimensions based on device type
                        double cardHeight;
                        double cardWidth;

                        if (isMobile) {
                          // Mobile: current size (smaller cards)
                          cardHeight = (availableHeight * 0.8).clamp(300.0, 600.0);
                          cardWidth = (availableWidth * 0.85).clamp(350.0, 500.0);
                        } else if (isTablet) {
                          // Tablet: medium size
                          cardHeight = (availableHeight * 0.85).clamp(400.0, 700.0);
                          cardWidth = (availableWidth * 0.7).clamp(450.0, 650.0);
                        } else {
                          // Desktop: larger cards for better visibility
                          cardHeight = (availableHeight * 0.9).clamp(500.0, 800.0);
                          cardWidth = (availableWidth * 0.6).clamp(500.0, 700.0);
                        }

                        // Calculate actual card dimensions (smaller than container)
                        final actualCardWidth = cardWidth * 0.75; // 75% of container width
                        final actualCardHeight = cardHeight * 0.75; // 75% of container height

                        return Stack(
                              alignment: Alignment.center,
                              children: [
                              uncategorizedTransactions.isEmpty
                                  ? Center(child: _buildCompletionCard(context))
                                  : Align(
                                      alignment: const Alignment(0.75, 0.0), // 75% to the right, centered vertically
                                      child: SizedBox(
                                        width: actualCardWidth,
                                        height: actualCardHeight,
                                        child: CardSwiper(
                                          controller: _controller,
                                          cardsCount: uncategorizedTransactions.length,
                                          numberOfCardsDisplayed: uncategorizedTransactions.length >= 2 ? 2 : 1,
                                          backCardOffset: const Offset(0, -20),
                                          padding: EdgeInsets.zero,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            if (currentIndex != null) {
                              setState(() {
                                _currentCardIndex = currentIndex;
                              });
                            }
                            return _onSwipe(
                              previousIndex,
                              direction,
                              uncategorizedTransactions,
                              categoryProvider,
                              transactionProvider,
                            );
                          },
                          cardBuilder: (context, index,
                              horizontalOffsetPercentage,
                              verticalOffsetPercentage) {
                            // Bounds check to prevent index out of range errors
                            if (index >= uncategorizedTransactions.length) {
                              return const SizedBox.shrink();
                            }

                            // Track offsets for diagonal detection
                            if (index == _currentCardIndex) {
                              _lastHorizontalOffset = horizontalOffsetPercentage.toDouble();
                              _lastVerticalOffset = verticalOffsetPercentage.toDouble();

                              // Track peak offsets in each direction (preserving sign)
                              // Update peak if current offset has greater absolute value
                              final currentH = horizontalOffsetPercentage.toDouble();
                              final currentV = verticalOffsetPercentage.toDouble();

                              if (currentH.abs() > _peakHorizontalOffset.abs()) {
                                _peakHorizontalOffset = currentH;
                              }
                              if (currentV.abs() > _peakVerticalOffset.abs()) {
                                _peakVerticalOffset = currentV;
                              }
                            }

                            final transaction = uncategorizedTransactions[index];
                            // Only show delete button on the top card (current card index)
                            final isTopCard = index == _currentCardIndex;
                            return TransactionCard(
                              transaction: transaction,
                              horizontalOffsetPercentage:
                                  horizontalOffsetPercentage.toDouble(),
                              verticalOffsetPercentage:
                                  verticalOffsetPercentage.toDouble(),
                              categories: categories,
                              swipeMappings: categoryProvider.swipeMappings,
                              // Only provide onDelete for the top card
                              onDelete: isTopCard ? () async {
                                // Delete the transaction
                                await transactionProvider.deleteTransaction(transaction.id);

                                // Show confirmation
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Deleted ${transaction.name}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } : null,
                            );
                          },
                                        ),
                                      ),
                                    ),
                              // Card counter - temporarily removed for testing alignment
                              // if (uncategorizedTransactions.isNotEmpty)
                              //   Positioned(
                              //     top: -10,
                              //     right: 20,
                              //     child: Container(...),
                              //   ),
                              ],
                        );
                      },
                    ),
                  ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    // Count items in "Other" category
    final otherCategory = categoryProvider.categories.where((c) => c.name.toLowerCase() == 'other');
    final otherCount = otherCategory.isNotEmpty
        ? transactionProvider.transactions
            .where((t) => t.category == otherCategory.first.id && t.isCategorized)
            .length
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Celebration icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),

            // Congratulations text
            Text(
              'All Caught Up!',
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              'You\'ve categorized all transactions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Show refinement button if items in Other
            if (otherCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9500), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      '📦 $otherCount items in "Other"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Let\'s organize them into categories',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OtherRefinementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Organize Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9500),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  HomeScreen.switchTab(context, 1);
                },
                child: const Text('Maybe Later'),
              ),
            ] else
              // View Charts button (when no items in Other)
              ElevatedButton.icon(
                onPressed: () {
                  HomeScreen.switchTab(context, 1);
                },
                icon: const Icon(Icons.pie_chart_rounded, size: 16),
                label: const Text('View Charts'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
          ],
        ),
          ),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    CardSwiperDirection direction,
    List<Transaction> transactions,
    CategoryProvider categoryProvider,
    TransactionProvider transactionProvider,
  ) {
    if (previousIndex >= transactions.length) return false;

    final transaction = transactions[previousIndex];

    // Map swipe direction to category using offset-based diagonal detection
    model.SwipeDirection? swipeDirection;

    // Use angle-based 8-direction detection for fluid, natural feel
    // Use peak offsets (which preserve sign and magnitude) from the swipe
    // INVERT vertical axis: screen coords have +Y down, but we want +Y up for angles
    // BOOST vertical sensitivity: users swipe quickly and release early, so vertical
    // movement is smaller than horizontal. Multiply by 2.5x to make diagonals easier.
    const verticalSensitivity = 2.5;
    final adjustedVertical = -_peakVerticalOffset * verticalSensitivity;
    final angleRad = atan2(adjustedVertical, _peakHorizontalOffset);
    final angleDeg = angleRad * 180 / pi;

    // Normalize to 0-360 range (0° = right, 90° = up, 180° = left, 270° = down)
    final normalizedAngle = (angleDeg + 360) % 360;

    // Divide into 8 equal 45° slices, each centered on a direction
    // After inverting Y: 0°=RIGHT, 90°=UP, 180°=LEFT, 270°=DOWN
    // The atan2 function returns angles in standard mathematical orientation:
    //   - 0° points right (+X axis)
    //   - 90° points up (+Y axis, which we inverted to match "up on screen")
    //   - 180° points left (-X axis)
    //   - 270° points down (-Y axis, which we inverted to match "down on screen")
    //
    // 337.5-22.5° → RIGHT swipe (right, ~zero vertical)
    // 22.5-67.5° → TOP-RIGHT swipe (right + upward on screen)
    // 67.5-112.5° → UP swipe (~zero horizontal, upward on screen)
    // 112.5-157.5° → TOP-LEFT swipe (left + upward on screen)
    // 157.5-202.5° → LEFT swipe (left, ~zero vertical)
    // 202.5-247.5° → BOTTOM-LEFT swipe (left + downward on screen)
    // 247.5-292.5° → DOWN swipe (~zero horizontal, downward on screen)
    // 292.5-337.5° → BOTTOM-RIGHT swipe (right + downward on screen)

    if (normalizedAngle >= 337.5 || normalizedAngle < 22.5) {
      swipeDirection = model.SwipeDirection.right;
    } else if (normalizedAngle >= 22.5 && normalizedAngle < 67.5) {
      swipeDirection = model.SwipeDirection.topRight;
    } else if (normalizedAngle >= 67.5 && normalizedAngle < 112.5) {
      swipeDirection = model.SwipeDirection.up;
    } else if (normalizedAngle >= 112.5 && normalizedAngle < 157.5) {
      swipeDirection = model.SwipeDirection.topLeft;
    } else if (normalizedAngle >= 157.5 && normalizedAngle < 202.5) {
      swipeDirection = model.SwipeDirection.left;
    } else if (normalizedAngle >= 202.5 && normalizedAngle < 247.5) {
      swipeDirection = model.SwipeDirection.bottomLeft;
    } else if (normalizedAngle >= 247.5 && normalizedAngle < 292.5) {
      swipeDirection = model.SwipeDirection.down;
    } else {
      swipeDirection = model.SwipeDirection.bottomRight;
    }

    // Ensure we have a valid swipe direction
    if (swipeDirection == null) {
      print('⚠️  Swipe direction could not be determined');
      return false;
    }

    // Get category for this swipe direction
    final categoryId = categoryProvider.getCategoryForSwipe(swipeDirection);

    // Debug logging
    print('🔍 Swipe Debug:');
    print('   Direction: $direction -> $swipeDirection');
    print('   Peak Offsets: H=${_peakHorizontalOffset.toStringAsFixed(2)}, V=${_peakVerticalOffset.toStringAsFixed(2)}');
    print('   Final Offsets: H=${_lastHorizontalOffset.toStringAsFixed(2)}, V=${_lastVerticalOffset.toStringAsFixed(2)}');
    print('   Angle: ${normalizedAngle.toStringAsFixed(1)}°');
    print('   Category ID: $categoryId');
    print('   Transaction: ${transaction.name}');

    if (categoryId != null) {
      // Categorize the transaction
      transactionProvider.categorizeTransaction(transaction.id, categoryId);

      // Show snackbar with category name
      final category = categoryProvider.getCategoryById(categoryId);
      if (category != null) {
        print('   ✅ Assigned to: ${category.name}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Categorized as ${category.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: category.color,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Reset offset tracking for next card
      _lastHorizontalOffset = 0.0;
      _lastVerticalOffset = 0.0;
      _peakHorizontalOffset = 0.0;
      _peakVerticalOffset = 0.0;

      return true;
    }

    return false;
  }
}

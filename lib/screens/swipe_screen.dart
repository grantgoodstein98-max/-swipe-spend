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
  bool _showCategorizedList = false;
  int _currentCardIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

          // Show loading if categories are loading
          if (categoryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Categorized transactions list at top
              if (categorizedTransactions.isNotEmpty)
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
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate card size - make it half the height of available space
                        final availableHeight = constraints.maxHeight;
                        final cardHeight = (availableHeight * 0.5).clamp(200.0, 300.0);
                        final cardWidth = cardHeight * 1.2; // Slightly wider than tall

                        return Center(
                          child: SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                              uncategorizedTransactions.isEmpty
                                  ? _buildCompletionCard(context)
                                  : CardSwiper(
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
                        // Card counter - only show when there are transactions
                        if (uncategorizedTransactions.isNotEmpty)
                          Positioned(
                            top: -10,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.brightness == Brightness.light
                                      ? Colors.black.withOpacity(0.08)
                                      : Colors.white.withOpacity(0.15),
                                  width: 0.5,
                                ),
                                boxShadow: theme.brightness == Brightness.light
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                '${uncategorizedTransactions.length}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

    // Map swipe direction to category
    model.SwipeDirection? swipeDirection;
    switch (direction) {
      case CardSwiperDirection.top:
        swipeDirection = model.SwipeDirection.up;
        break;
      case CardSwiperDirection.bottom:
        swipeDirection = model.SwipeDirection.down;
        break;
      case CardSwiperDirection.left:
        swipeDirection = model.SwipeDirection.left;
        break;
      case CardSwiperDirection.right:
        swipeDirection = model.SwipeDirection.right;
        break;
      default:
        return false;
    }

    // Get category for this swipe direction
    final categoryId = categoryProvider.getCategoryForSwipe(swipeDirection);

    if (categoryId != null) {
      // Categorize the transaction
      transactionProvider.categorizeTransaction(transaction.id, categoryId);

      // Show snackbar with category name
      final category = categoryProvider.getCategoryById(categoryId);
      if (category != null) {
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

      return true;
    }

    return false;
  }
}

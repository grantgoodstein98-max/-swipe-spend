import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as model;
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/category_indicator.dart';

/// Screen for swiping to categorize transactions
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  bool _showCategorizedList = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorize Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Show count of uncategorized transactions
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              final uncategorizedCount =
                  transactionProvider.uncategorizedTransactions.length;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    '$uncategorizedCount left',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categorized (${categorizedTransactions.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: Icon(_showCategorizedList
                                ? Icons.expand_less
                                : Icons.expand_more),
                            onPressed: () {
                              setState(() {
                                _showCategorizedList = !_showCategorizedList;
                              });
                            },
                          ),
                        ],
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
                child: Stack(
                  children: [
                    // Category indicators around the edges
                    CategoryIndicator(
                      categories: categories,
                      swipeMappings: categoryProvider.swipeMappings,
                      categoryTotals: categoryTotals,
                    ),

                    // Main swipe area with card
                    Center(
                      child: uncategorizedTransactions.isEmpty
                          ? _buildEmptyState(context)
                          : Container(
                              constraints: BoxConstraints(
                                maxWidth: 300,
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: CardSwiper(
                                  controller: _controller,
                                  cardsCount: uncategorizedTransactions.length,
                                  numberOfCardsDisplayed: 2,
                                  backCardOffset: const Offset(0, -20),
                                  padding: const EdgeInsets.all(24),
                                  onSwipe: (previousIndex, currentIndex,
                                      direction) {
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
                                    return TransactionCard(
                                      transaction:
                                          uncategorizedTransactions[index],
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 250,
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surfaceVariant,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions left',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'All transactions have been categorized!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
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

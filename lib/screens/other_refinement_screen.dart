import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Screen for refining "Other" category transactions into specific categories
class OtherRefinementScreen extends StatefulWidget {
  const OtherRefinementScreen({super.key});

  @override
  State<OtherRefinementScreen> createState() => _OtherRefinementScreenState();
}

class _OtherRefinementScreenState extends State<OtherRefinementScreen> {
  int _currentCategoryIndex = 0;
  List<Category> _nonSwipeCategories = [];
  List<Transaction> _otherTransactions = [];
  final Set<String> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    // Get all categories that are NOT assigned to swipe directions
    final swipeCategories = {
      categoryProvider.getCategoryForSwipe(SwipeDirection.up),
      categoryProvider.getCategoryForSwipe(SwipeDirection.down),
      categoryProvider.getCategoryForSwipe(SwipeDirection.left),
      categoryProvider.getCategoryForSwipe(SwipeDirection.right),
    }.where((id) => id != null).toSet();

    _nonSwipeCategories = categoryProvider.categories
        .where((c) => !swipeCategories.contains(c.id) && c.name.toLowerCase() != 'other')
        .toList();

    // Get all transactions currently in "Other" category
    final otherCategory = categoryProvider.categories
        .firstWhere((c) => c.name.toLowerCase() == 'other');

    _otherTransactions = transactionProvider.transactions
        .where((t) => t.category == otherCategory.id && t.isCategorized)
        .toList();

    debugPrint('📋 Found ${_nonSwipeCategories.length} non-swipe categories');
    debugPrint('📋 Found ${_otherTransactions.length} transactions in Other');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCategoryIndex >= _nonSwipeCategories.length) {
      return _buildCompletionScreen();
    }

    final currentCategory = _nonSwipeCategories[_currentCategoryIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with X button and progress
            _buildHeader(context),

            // Current category display
            _buildCategoryHeader(currentCategory, isDark),

            // Transaction list with checkboxes
            Expanded(
              child: _buildTransactionList(currentCategory, isDark),
            ),

            // Submit button
            _buildSubmitButton(context, currentCategory),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final progress = (_currentCategoryIndex + 1) / _nonSwipeCategories.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Organize Your Spending',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _showExitDialog(context),
                tooltip: 'Take a break',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE5E5EA),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Category ${_currentCategoryIndex + 1} of ${_nonSwipeCategories.length}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(Category category, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              category.icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select all ${category.name.toLowerCase()} transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(Category category, bool isDark) {
    if (_otherTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions left!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _otherTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _otherTransactions[index];
        final isSelected = _selectedTransactionIds.contains(transaction.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? category.color
                  : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedTransactionIds.add(transaction.id);
                } else {
                  _selectedTransactionIds.remove(transaction.id);
                }
              });
            },
            activeColor: category.color,
            title: Text(
              transaction.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            secondary: Text(
              '\$${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context, Category category) {
    final hasSelections = _selectedTransactionIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSelections)
            Text(
              '${_selectedTransactionIds.length} selected',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentCategoryIndex++;
                      _selectedTransactionIds.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: hasSelections ? () => _submitSelections(category) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: category.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    hasSelections ? 'Submit & Continue' : 'Skip or Select Items',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                size: 100,
                color: Color(0xFF34C759),
              ),
              const SizedBox(height: 24),
              const Text(
                'All Done!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your spending is now organized',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Charts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitSelections(Category category) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    // Move selected transactions to this category
    for (var transactionId in _selectedTransactionIds) {
      transactionProvider.recategorizeTransaction(transactionId, category.id);
    }

    // Remove categorized transactions from list
    _otherTransactions.removeWhere((t) => _selectedTransactionIds.contains(t.id));

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_selectedTransactionIds.length} moved to ${category.name}'),
          backgroundColor: const Color(0xFF34C759),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Move to next category
    setState(() {
      _selectedTransactionIds.clear();
      _currentCategoryIndex++;
    });
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take a Break?'),
        content: const Text('Your progress is saved. You can continue anytime!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close refinement screen
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/guest_mode_provider.dart';
import '../providers/plaid_provider.dart';
import '../widgets/add_category_dialog.dart';
import 'import_transactions_screen.dart';
import '../services/auth_service.dart';

/// Screen for managing categories and app settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.displayLarge,
        ),
      ),
      body: Consumer3<CategoryProvider, ThemeProvider, GuestModeProvider>(
        builder: (context, categoryProvider, themeProvider, guestModeProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final categories = categoryProvider.categories;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // iOS-style Account Section
              _buildSectionHeader(context, 'ACCOUNT'),
              Container(
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
                  children: [
                    // User Email Row or Guest Mode Indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              guestModeProvider.isGuestMode
                                  ? Icons.person_outline
                                  : Icons.person_outline,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guestModeProvider.isGuestMode
                                      ? 'Guest Mode'
                                      : 'Signed in as',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  guestModeProvider.isGuestMode
                                      ? 'Data will not be saved'
                                      : AuthService().currentUser?.email ?? 'Unknown',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(context),
                    // Connect Bank Account Button
                    Consumer<PlaidProvider>(
                      builder: (context, plaidProvider, child) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: plaidProvider.isLinked
                                ? () => _showDisconnectBankDialog(context, plaidProvider)
                                : () => plaidProvider.connectBankAccount(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: plaidProvider.isLinked
                                          ? Colors.green.withOpacity(0.1)
                                          : theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      plaidProvider.isLinked
                                          ? Icons.account_balance
                                          : Icons.add_link,
                                      color: plaidProvider.isLinked
                                          ? Colors.green
                                          : theme.colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plaidProvider.isLinked
                                              ? 'Connected Bank'
                                              : 'Connect Bank Account',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (plaidProvider.isLinked && plaidProvider.linkedInstitutionName != null)
                                          Text(
                                            plaidProvider.linkedInstitutionName!,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (plaidProvider.isLinked)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDivider(context),
                    // Sign Out / Exit Guest Mode Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleSignOut(context, guestModeProvider),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  guestModeProvider.isGuestMode
                                      ? Icons.exit_to_app
                                      : Icons.logout,
                                  color: theme.colorScheme.error,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                guestModeProvider.isGuestMode
                                    ? 'Exit Guest Mode'
                                    : 'Sign Out',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // iOS-style Appearance Section
              _buildSectionHeader(context, 'APPEARANCE'),
              Container(
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
                child: SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    themeProvider.isDarkMode
                        ? 'OLED-friendly dark theme'
                        : 'Classic light theme',
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ),

              // iOS-style Data Management Section
              _buildSectionHeader(context, 'DATA'),
              Container(
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImportTransactionsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.upload_file,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Import Transactions',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'From CSV or Excel file',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.textTheme.bodySmall?.color,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // iOS-style Categories Section
              _buildSectionHeader(context, 'CATEGORIES'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Manage your spending categories',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 12),

              // Categories list
              Container(
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
                  children: [
                    ...List.generate(
                      categories.length,
                      (index) {
                        final category = categories[index];
                        return Column(
                          children: [
                            if (index > 0) _buildDivider(context),
                            _buildCategoryRow(
                              context,
                              category,
                              categoryProvider,
                              isFirst: index == 0,
                              isLast: index == categories.length - 1,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Add Category button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAddCategoryDialog(context, categoryProvider),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add Category',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // iOS-style Swipe Mapping Section
              _buildSectionHeader(context, 'SWIPE MAPPING'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Configure which category each swipe direction triggers',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 12),

              // Swipe direction cards with iOS grouped style
              Container(
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
                  children: [
                    _buildSwipeDirectionRow(
                      context,
                      'Swipe Up',
                      Icons.arrow_upward_rounded,
                      model.SwipeDirection.up,
                      categories,
                      categoryProvider,
                      isFirst: true,
                    ),
                    _buildDivider(context),
                    _buildSwipeDirectionRow(
                      context,
                      'Swipe Down',
                      Icons.arrow_downward_rounded,
                      model.SwipeDirection.down,
                      categories,
                      categoryProvider,
                    ),
                    _buildDivider(context),
                    _buildSwipeDirectionRow(
                      context,
                      'Swipe Left',
                      Icons.arrow_back_rounded,
                      model.SwipeDirection.left,
                      categories,
                      categoryProvider,
                    ),
                    _buildDivider(context),
                    _buildSwipeDirectionRow(
                      context,
                      'Swipe Right',
                      Icons.arrow_forward_rounded,
                      model.SwipeDirection.right,
                      categories,
                      categoryProvider,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// iOS-style section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
      ),
    );
  }

  /// iOS-style divider within grouped cards
  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark
            ? const Color(0xFF38383A).withOpacity(0.5)
            : const Color(0xFFD1D1D6),
      ),
    );
  }

  /// iOS-style row for swipe direction within grouped card
  Widget _buildSwipeDirectionRow(
    BuildContext context,
    String title,
    IconData icon,
    model.SwipeDirection direction,
    List<model.Category> categories,
    CategoryProvider categoryProvider, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final categoryId = categoryProvider.getCategoryForSwipe(direction);
    final currentCategory = categoryId != null
        ? categoryProvider.getCategoryById(categoryId)
        : null;
    final isDownDirection = direction == model.SwipeDirection.down;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDownDirection
            ? null // Disable tap for down direction
            : () => _showCategoryPicker(
                  context,
                  title,
                  direction,
                  categories,
                  categoryProvider,
                ),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Direction icon - iOS style
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Direction label and current category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    if (currentCategory != null)
                      Row(
                        children: [
                          Icon(
                            currentCategory.icon,
                            size: 14,
                            color: currentCategory.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentCategory.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: currentCategory.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Not assigned',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),

              // iOS-style chevron or lock icon
              Icon(
                isDownDirection ? Icons.lock_outline : Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// iOS-style modal bottom sheet for category selection
  void _showCategoryPicker(
    BuildContext context,
    String directionTitle,
    model.SwipeDirection direction,
    List<model.Category> categories,
    CategoryProvider categoryProvider,
  ) {
    // Don't allow changing down swipe (reserved for "Other")
    if (direction == model.SwipeDirection.down) {
      return;
    }

    // Filter out "Other" category for non-down directions
    final selectableCategories = categories
        .where((c) => c.name.toLowerCase() != 'other')
        .toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with iOS-style dismiss indicator
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select Category',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Text(
                  directionTitle,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const Divider(height: 1),
              // Category list
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectableCategories.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final category = selectableCategories[index];
                    final isCurrentlyMapped =
                        categoryProvider.getCategoryForSwipe(direction) ==
                            category.id;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          categoryProvider.mapSwipeToCategory(
                              direction, category.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$directionTitle → ${category.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: category.color,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Category icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: category.color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Category name
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              // Checkmark if selected
                              if (isCurrentlyMapped)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 22,
                                ),
                            ],
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

  /// Build a category row in the categories list
  Widget _buildCategoryRow(
    BuildContext context,
    model.Category category,
    CategoryProvider categoryProvider, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditCategoryDialog(context, category, categoryProvider),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Category name
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                onPressed: () => _showDeleteCategoryDialog(
                  context,
                  category,
                  categoryProvider,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get display name for swipe direction
  String _getDirectionDisplayName(model.SwipeDirection direction) {
    switch (direction) {
      case model.SwipeDirection.up:
        return 'Swipe Up';
      case model.SwipeDirection.down:
        return 'Swipe Down';
      case model.SwipeDirection.left:
        return 'Swipe Left';
      case model.SwipeDirection.right:
        return 'Swipe Right';
    }
  }

  /// Show add category dialog
  Future<void> _showAddCategoryDialog(
    BuildContext context,
    CategoryProvider categoryProvider,
  ) async {
    final newCategory = await AddCategoryDialog.showAdd(context);

    if (newCategory != null) {
      try {
        await categoryProvider.addCategory(newCategory);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newCategory.name} added'),
              backgroundColor: newCategory.color,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding category: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Show edit category dialog
  Future<void> _showEditCategoryDialog(
    BuildContext context,
    model.Category category,
    CategoryProvider categoryProvider,
  ) async {
    final updatedCategory = await AddCategoryDialog.showEdit(
      context,
      category,
    );

    if (updatedCategory != null) {
      try {
        await categoryProvider.updateCategory(updatedCategory);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedCategory.name} updated'),
              backgroundColor: updatedCategory.color,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating category: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Show delete category confirmation dialog
  Future<void> _showDeleteCategoryDialog(
    BuildContext context,
    model.Category category,
    CategoryProvider categoryProvider,
  ) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Category?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await categoryProvider.deleteCategory(category.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${category.name} deleted'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting category: $e'),
              backgroundColor: theme.colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Handle sign out or exit guest mode with confirmation
  Future<void> _handleSignOut(BuildContext context, GuestModeProvider guestModeProvider) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGuest = guestModeProvider.isGuestMode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isGuest ? 'Exit Guest Mode?' : 'Sign Out?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isGuest
              ? 'Your data will be lost. Are you sure you want to exit guest mode?'
              : 'Are you sure you want to sign out?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(isGuest ? 'Exit' : 'Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isGuest) {
          guestModeProvider.exitGuestMode();
        } else {
          await AuthService().signOut();
        }
        // Navigate back to login screen by popping to root
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: theme.colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Show disconnect bank account dialog
  static void _showDisconnectBankDialog(BuildContext context, PlaidProvider plaidProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disconnect Bank?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will remove your bank connection. You can reconnect anytime.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              plaidProvider.disconnect();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bank account disconnected'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

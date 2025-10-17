import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';

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
      body: Consumer2<CategoryProvider, ThemeProvider>(
        builder: (context, categoryProvider, themeProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final categories = categoryProvider.categories;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCategoryPicker(
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

              // iOS-style chevron
              Icon(
                Icons.chevron_right,
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
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
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
}

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/category.dart' as model;
import '../widgets/icon_picker.dart';
import '../utils/available_icons.dart';

/// Dialog for adding or editing a category
class AddCategoryDialog extends StatefulWidget {
  final model.Category? existingCategory;
  final List<model.SwipeDirection> availableDirections;

  const AddCategoryDialog({
    super.key,
    this.existingCategory,
    required this.availableDirections,
  });

  /// Show the dialog for adding a new category
  static Future<model.Category?> showAdd(
    BuildContext context,
    List<model.SwipeDirection> availableDirections,
  ) {
    return showDialog<model.Category>(
      context: context,
      builder: (context) => AddCategoryDialog(
        availableDirections: availableDirections,
      ),
    );
  }

  /// Show the dialog for editing an existing category
  static Future<model.Category?> showEdit(
    BuildContext context,
    model.Category category,
    List<model.SwipeDirection> availableDirections,
  ) {
    return showDialog<model.Category>(
      context: context,
      builder: (context) => AddCategoryDialog(
        existingCategory: category,
        availableDirections: availableDirections,
      ),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _iconName = 'category';
  Color _color = const Color(0xFF607D8B);
  model.SwipeDirection? _swipeDirection;

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _nameController.text = widget.existingCategory!.name;
      _iconName = widget.existingCategory!.iconName;
      _color = widget.existingCategory!.color;
      _swipeDirection = widget.existingCategory!.swipeDirection;
    } else if (widget.availableDirections.isNotEmpty) {
      _swipeDirection = widget.availableDirections.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final iconName = await IconPicker.show(
      context,
      currentIconName: _iconName,
      categoryColor: _color,
    );
    if (iconName != null) {
      setState(() {
        _iconName = iconName;
      });
    }
  }

  Future<void> _pickColor() async {
    Color? selectedColor;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _color,
              onColorChanged: (color) {
                selectedColor = color;
              },
              availableColors: const [
                Color(0xFFF44336), // Red
                Color(0xFFE91E63), // Pink
                Color(0xFF9C27B0), // Purple
                Color(0xFF673AB7), // Deep Purple
                Color(0xFF3F51B5), // Indigo
                Color(0xFF2196F3), // Blue
                Color(0xFF03A9F4), // Light Blue
                Color(0xFF00BCD4), // Cyan
                Color(0xFF009688), // Teal
                Color(0xFF4CAF50), // Green
                Color(0xFF8BC34A), // Light Green
                Color(0xFFCDDC39), // Lime
                Color(0xFFFFEB3B), // Yellow
                Color(0xFFFFC107), // Amber
                Color(0xFFFF9800), // Orange
                Color(0xFFFF5722), // Deep Orange
                Color(0xFF795548), // Brown
                Color(0xFF607D8B), // Blue Grey
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedColor != null) {
                  setState(() {
                    _color = selectedColor!;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  String _getDirectionName(model.SwipeDirection direction) {
    switch (direction) {
      case model.SwipeDirection.up:
        return 'Up';
      case model.SwipeDirection.down:
        return 'Down';
      case model.SwipeDirection.left:
        return 'Left';
      case model.SwipeDirection.right:
        return 'Right';
    }
  }

  bool _canSave() {
    return _nameController.text.trim().isNotEmpty &&
           _swipeDirection != null;
  }

  void _save() {
    if (!_canSave()) return;

    final category = model.Category(
      id: widget.existingCategory?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      colorHex: _color.value.toRadixString(16).substring(2).toUpperCase(),
      swipeDirection: _swipeDirection!,
      iconName: _iconName,
    );

    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingCategory != null;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Category' : 'Add Category',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Groceries',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Icon picker
            InkWell(
              onTap: _pickIcon,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AvailableIcons.getIcon(_iconName),
                        color: _color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Icon',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            AvailableIcons.getDisplayName(_iconName),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            InkWell(
              onTap: _pickColor,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            '#${_color.value.toRadixString(16).substring(2).toUpperCase()}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Swipe direction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swipe Direction',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<model.SwipeDirection>(
                    value: _swipeDirection,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: widget.availableDirections.map((direction) {
                      return DropdownMenuItem(
                        value: direction,
                        child: Row(
                          children: [
                            Icon(
                              _getDirectionIcon(direction),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(_getDirectionName(direction)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _swipeDirection = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canSave() ? _save : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isEditing ? 'Save' : 'Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDirectionIcon(model.SwipeDirection direction) {
    switch (direction) {
      case model.SwipeDirection.up:
        return Icons.arrow_upward;
      case model.SwipeDirection.down:
        return Icons.arrow_downward;
      case model.SwipeDirection.left:
        return Icons.arrow_back;
      case model.SwipeDirection.right:
        return Icons.arrow_forward;
    }
  }
}

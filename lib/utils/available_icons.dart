import 'package:flutter/material.dart';

/// Helper class for available category icons
class AvailableIcons {
  /// Map of icon names to IconData
  static const Map<String, IconData> iconMap = {
    // Food & Dining
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'local_pizza': Icons.local_pizza,
    'fastfood': Icons.fastfood,
    'local_bar': Icons.local_bar,
    'lunch_dining': Icons.lunch_dining,

    // Transportation
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'train': Icons.train,
    'flight': Icons.flight,
    'local_taxi': Icons.local_taxi,
    'two_wheeler': Icons.two_wheeler,

    // Shopping
    'shopping_bag': Icons.shopping_bag,
    'shopping_cart': Icons.shopping_cart,
    'store': Icons.store,
    'local_mall': Icons.local_mall,
    'storefront': Icons.storefront,

    // Entertainment
    'movie': Icons.movie,
    'theaters': Icons.theaters,
    'sports_esports': Icons.sports_esports,
    'music_note': Icons.music_note,
    'camera_alt': Icons.camera_alt,
    'sports_soccer': Icons.sports_soccer,

    // Bills & Utilities
    'receipt': Icons.receipt,
    'receipt_long': Icons.receipt_long,
    'bolt': Icons.bolt,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,

    // Health & Fitness
    'fitness_center': Icons.fitness_center,
    'local_hospital': Icons.local_hospital,
    'medication': Icons.medication,
    'spa': Icons.spa,
    'self_improvement': Icons.self_improvement,

    // Home & Garden
    'home': Icons.home,
    'bed': Icons.bed,
    'weekend': Icons.weekend,
    'yard': Icons.yard,
    'cottage': Icons.cottage,

    // Education
    'school': Icons.school,
    'book': Icons.book,
    'menu_book': Icons.menu_book,
    'library_books': Icons.library_books,

    // Work & Business
    'work': Icons.work,
    'business': Icons.business,
    'computer': Icons.computer,
    'devices': Icons.devices,

    // Finance
    'account_balance': Icons.account_balance,
    'savings': Icons.savings,
    'attach_money': Icons.attach_money,
    'credit_card': Icons.credit_card,
    'wallet': Icons.wallet,

    // Travel & Hotel
    'hotel': Icons.hotel,
    'luggage': Icons.luggage,
    'beach_access': Icons.beach_access,
    'map': Icons.map,

    // Pets
    'pets': Icons.pets,

    // Gifts
    'card_giftcard': Icons.card_giftcard,
    'celebration': Icons.celebration,

    // Other
    'category': Icons.category,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'settings': Icons.settings,
    'help_outline': Icons.help_outline,
  };

  /// Get IconData from icon name
  static IconData getIcon(String iconName) {
    return iconMap[iconName] ?? Icons.help_outline;
  }

  /// Get icon name from IconData
  static String? getIconName(IconData icon) {
    for (final entry in iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get list of all available icon names
  static List<String> get allIconNames => iconMap.keys.toList();

  /// Get list of all available icons
  static List<IconData> get allIcons => iconMap.values.toList();

  /// Get display name for an icon
  static String getDisplayName(String iconName) {
    return iconName.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

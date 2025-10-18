import 'package:flutter/foundation.dart';

/// Provider for managing guest mode state
class GuestModeProvider extends ChangeNotifier {
  bool _isGuestMode = false;

  /// Check if user is in guest mode
  bool get isGuestMode => _isGuestMode;

  /// Enable guest mode
  void enableGuestMode() {
    _isGuestMode = true;
    notifyListeners();
  }

  /// Disable guest mode (when user signs in/up)
  void disableGuestMode() {
    _isGuestMode = false;
    notifyListeners();
  }

  /// Exit guest mode and return to login
  void exitGuestMode() {
    _isGuestMode = false;
    notifyListeners();
  }
}

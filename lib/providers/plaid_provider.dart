import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/plaid_service.dart';
import '../models/transaction.dart';

/// Provider for managing Plaid integration state
class PlaidProvider extends ChangeNotifier {
  final PlaidService _plaidService = PlaidService();
  bool _isLoading = false;
  String? _error;
  List<Transaction> _plaidTransactions = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLinked => _plaidService.isLinked;
  String? get linkedInstitutionName => _plaidService.linkedInstitutionName;
  List<Transaction> get plaidTransactions => _plaidTransactions;

  /// Initialize and open Plaid Link (works on web and mobile)
  Future<void> connectBankAccount(BuildContext context) async {
    _setLoading(true);
    _clearError();

    try {
      // Open Plaid Link (works on both web via JS SDK and mobile via Flutter package)
      final result = await _plaidService.openPlaidLink();

      if (result != null) {
        final publicToken = result['publicToken'] as String;
        final metadata = result['metadata'] as Map<String, dynamic>;
        final institutionName = metadata['institution']?['name'] as String? ?? 'Bank';

        debugPrint('✅ Plaid Link Success!');
        debugPrint('   Public Token: ${publicToken.substring(0, 20)}...');
        debugPrint('   Institution: $institutionName');

        // Save institution name
        _plaidService.linkedInstitutionName = institutionName;

        // Exchange public token for access token
        final success = await _plaidService.exchangePublicToken(publicToken);

        if (success) {
          debugPrint('✅ Bank account connected successfully!');
          notifyListeners();

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Connected to $institutionName!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          _setError('Failed to connect bank account');
        }
      } else {
        debugPrint('ℹ️  Plaid Link closed by user');
      }

      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Error opening Plaid Link: $e');
      _setError(e.toString());
      _setLoading(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Plaid Link: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Sync transactions from Plaid
  Future<List<Transaction>> syncTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_plaidService.isLinked) {
      throw Exception('No bank account linked');
    }

    _setLoading(true);
    _clearError();

    try {
      final transactions = await _plaidService.fetchTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      _plaidTransactions = transactions;
      debugPrint('✅ Synced ${transactions.length} transactions from Plaid');

      _setLoading(false);
      return transactions;
    } catch (e) {
      debugPrint('❌ Error syncing transactions: $e');
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }

  /// Disconnect bank account
  void disconnect() {
    _plaidService.disconnect();
    _plaidTransactions = [];
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

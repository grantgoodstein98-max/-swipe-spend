import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
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

  /// Initialize and open Plaid Link
  Future<void> connectBankAccount(BuildContext context) async {
    _setLoading(true);
    _clearError();

    try {
      await _plaidService.initializePlaidLink(
        onSuccess: (publicToken, metadata) async {
          debugPrint(' Plaid Link Success!');
          debugPrint('   Public Token: ${publicToken.substring(0, 20)}...');
          debugPrint('   Institution: ${metadata.institution.name}');

          // Save institution name
          _plaidService.linkedInstitutionName = metadata.institution.name;

          // Exchange public token for access token
          final success = await _plaidService.exchangePublicToken(publicToken);

          if (success) {
            debugPrint(' Bank account connected successfully!');
            notifyListeners();

            // Show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Connected to ${metadata.institution.name}!',
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

          _setLoading(false);
        },
        onError: (error, metadata) {
          debugPrint('L Plaid Link Error: ${error.errorMessage}');
          _setError(error.errorMessage);
          _setLoading(false);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.errorMessage}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        onEvent: (event, metadata) {
          debugPrint('=Ê Plaid Event: ${event.eventName}');
        },
      );

      // Open Plaid Link UI
      await _plaidService.openPlaidLink();
    } catch (e) {
      debugPrint('L Error opening Plaid Link: $e');
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
      debugPrint(' Synced ${transactions.length} transactions from Plaid');

      _setLoading(false);
      return transactions;
    } catch (e) {
      debugPrint('L Error syncing transactions: $e');
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/plaid_service_multi_bank.dart';
import '../models/transaction.dart';
import '../models/connected_bank.dart';

/// Enhanced provider for managing multi-bank Plaid integration
class PlaidProviderMultiBank extends ChangeNotifier {
  final PlaidServiceMultiBank _plaidService = PlaidServiceMultiBank();

  bool _isLoading = false;
  String? _error;
  List<ConnectedBank> _connectedBanks = [];
  Map<String, bool> _syncingBanks = {}; // Track which banks are currently syncing

  PlaidProviderMultiBank() {
    // Load connected banks on initialization
    loadConnectedBanks();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ConnectedBank> get connectedBanks => _connectedBanks;
  bool get hasConnectedBanks => _connectedBanks.isNotEmpty;
  int get connectedBankCount => _connectedBanks.length;

  // Check if a specific bank is syncing
  bool isBankSyncing(String institutionId) {
    return _syncingBanks[institutionId] ?? false;
  }

  /// Load connected banks from storage
  Future<void> loadConnectedBanks() async {
    try {
      _connectedBanks = await _plaidService.getConnectedBanks();
      notifyListeners();
      debugPrint('📋 Loaded ${_connectedBanks.length} connected banks');
    } catch (e) {
      debugPrint('❌ Error loading connected banks: $e');
      _setError(e.toString());
    }
  }

  /// Connect a new bank account
  Future<void> connectBankAccount(BuildContext context) async {
    _setLoading(true);
    _clearError();

    try {
      // Open Plaid Link
      final result = await _plaidService.openPlaidLink();

      if (result != null) {
        // Handle dynamic type from web/mobile Plaid Link
        final resultMap = result is Map<String, dynamic>
            ? result
            : Map<String, dynamic>.from(result as Map);

        final publicToken = resultMap['publicToken'] as String;
        final metadataRaw = resultMap['metadata'];
        final metadata = metadataRaw is Map<String, dynamic>
            ? metadataRaw
            : Map<String, dynamic>.from(metadataRaw as Map);

        // Extract institution info
        final institutionRaw = metadata['institution'];
        final institution = institutionRaw is Map<String, dynamic>
            ? institutionRaw
            : (institutionRaw != null ? Map<String, dynamic>.from(institutionRaw as Map) : null);

        final institutionId = institution?['institution_id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        final institutionName = institution?['name'] as String? ?? 'Bank';

        // Extract account info if available
        final accountsRaw = metadata['accounts'];
        final accounts = accountsRaw is List ? accountsRaw : [];
        final firstAccount = accounts.isNotEmpty ? accounts.first : null;

        String? accountMask;
        String? accountType;

        if (firstAccount != null) {
          final accountMap = firstAccount is Map<String, dynamic>
              ? firstAccount
              : Map<String, dynamic>.from(firstAccount as Map);
          accountMask = accountMap['mask'] as String?;
          accountType = accountMap['subtype'] as String?;
        }

        debugPrint('✅ Plaid Link Success!');
        debugPrint('   Institution ID: $institutionId');
        debugPrint('   Institution: $institutionName');

        // Add connected bank
        final bank = await _plaidService.addConnectedBank(
          publicToken: publicToken,
          institutionId: institutionId,
          institutionName: institutionName,
          accountMask: accountMask,
          accountType: accountType,
        );

        // Reload banks
        await loadConnectedBanks();

        _setLoading(false);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Connected to $institutionName!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('ℹ️  Plaid Link closed by user');
        _setLoading(false);
      }
    } catch (e) {
      debugPrint('❌ Error connecting bank: $e');
      _setError(e.toString());
      _setLoading(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect bank: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Sync transactions from a specific bank
  Future<List<Transaction>> syncBank(
    String institutionId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bank = _connectedBanks.firstWhere(
      (b) => b.institutionId == institutionId,
      orElse: () => throw Exception('Bank not found'),
    );

    _syncingBanks[institutionId] = true;
    notifyListeners();

    try {
      final transactions = await _plaidService.syncBank(
        bank,
        startDate: startDate,
        endDate: endDate,
      );

      // Reload banks to get updated sync time
      await loadConnectedBanks();

      _syncingBanks[institutionId] = false;
      notifyListeners();

      debugPrint('✅ Synced ${transactions.length} transactions from ${bank.institutionName}');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error syncing ${bank.institutionName}: $e');
      _syncingBanks[institutionId] = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sync all connected banks
  Future<Map<String, List<Transaction>>> syncAllBanks({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_connectedBanks.isEmpty) {
      throw Exception('No banks connected');
    }

    _setLoading(true);
    _clearError();

    try {
      final results = await _plaidService.syncAllBanks(
        startDate: startDate,
        endDate: endDate,
      );

      // Reload banks to get updated sync times
      await loadConnectedBanks();

      _setLoading(false);

      final totalTransactions = results.values.fold<int>(
        0,
        (sum, transactions) => sum + transactions.length,
      );

      debugPrint('✅ Synced $totalTransactions total transactions from ${results.length} banks');
      return results;
    } catch (e) {
      debugPrint('❌ Error syncing all banks: $e');
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  /// Disconnect a specific bank
  Future<void> disconnectBank(String institutionId) async {
    try {
      await _plaidService.disconnectBank(institutionId);
      await loadConnectedBanks();
      debugPrint('🔌 Disconnected bank: $institutionId');
    } catch (e) {
      debugPrint('❌ Error disconnecting bank: $e');
      _setError(e.toString());
      rethrow;
    }
  }

  /// Update bank nickname
  Future<void> updateBankNickname(String institutionId, String nickname) async {
    try {
      await _plaidService.updateBankNickname(institutionId, nickname);
      await loadConnectedBanks();
    } catch (e) {
      debugPrint('❌ Error updating bank nickname: $e');
      _setError(e.toString());
    }
  }

  /// Get a specific connected bank
  ConnectedBank? getBank(String institutionId) {
    try {
      return _connectedBanks.firstWhere((b) => b.institutionId == institutionId);
    } catch (e) {
      return null;
    }
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

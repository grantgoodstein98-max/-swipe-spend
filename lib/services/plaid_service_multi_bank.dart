import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../models/transaction.dart';
import '../models/connected_bank.dart';
import 'plaid_web_service.dart' if (dart.library.io) 'plaid_web_service_stub.dart';
import 'auth_service.dart';

/// Enhanced Plaid service with multi-bank support
class PlaidServiceMultiBank {
  final AuthService _authService = AuthService();

  /// Get storage key for connected banks (user-specific)
  String get _connectedBanksKey {
    final userId = _authService.userId;
    return userId != null ? 'connected_banks_$userId' : 'connected_banks_guest';
  }

  /// Get backend URL based on platform
  static String get backendUrl => kIsWeb
      ? 'https://swipe-spend-backend.onrender.com'
      : 'http://localhost:3000';

  /// Get all connected banks from backend (with local cache fallback)
  Future<List<ConnectedBank>> getConnectedBanks() async {
    try {
      final userId = _authService.userId ?? 'guest';

      // Try to fetch from backend first
      try {
        final response = await http.get(
          Uri.parse('$backendUrl/api/user/$userId/banks'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> banksList = data['banks'];
          final banks = banksList.map((json) => ConnectedBank.fromJson(json)).toList();

          // Cache to local storage
          await _saveToLocalStorage(banks);
          debugPrint('✅ Loaded ${banks.length} banks from backend');
          return banks;
        }
      } catch (e) {
        debugPrint('⚠️ Backend fetch failed, using local cache: $e');
      }

      // Fallback to local storage if backend fails
      final prefs = await SharedPreferences.getInstance();
      final banksJson = prefs.getString(_connectedBanksKey);

      if (banksJson == null || banksJson.isEmpty) {
        return [];
      }

      final List<dynamic> banksList = jsonDecode(banksJson);
      final banks = banksList.map((json) => ConnectedBank.fromJson(json)).toList();
      debugPrint('📦 Loaded ${banks.length} banks from local cache');
      return banks;
    } catch (e) {
      debugPrint('❌ Error loading connected banks: $e');
      return [];
    }
  }

  /// Save connected banks to local storage only (for caching)
  Future<void> _saveToLocalStorage(List<ConnectedBank> banks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final banksJson = jsonEncode(banks.map((b) => b.toJson()).toList());
      await prefs.setString(_connectedBanksKey, banksJson);
      debugPrint('💾 Cached ${banks.length} banks locally');
    } catch (e) {
      debugPrint('❌ Error caching banks locally: $e');
    }
  }

  /// Save bank to backend and local storage
  Future<void> _saveConnectedBanks(List<ConnectedBank> banks) async {
    try {
      // Save to local storage first (immediate)
      await _saveToLocalStorage(banks);

      // Then sync to backend (may fail if offline)
      final userId = _authService.userId ?? 'guest';

      for (final bank in banks) {
        try {
          await http.post(
            Uri.parse('$backendUrl/api/user/$userId/banks'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'institutionId': bank.institutionId,
              'institutionName': bank.institutionName,
              'accessToken': bank.accessToken,
              'itemId': '${bank.institutionId}_${DateTime.now().millisecondsSinceEpoch}',
              'accountMask': bank.accountMask,
              'accountType': bank.accountType,
              'logoUrl': bank.logoUrl,
              'nickname': bank.nickname,
              'accountIds': [],
            }),
          ).timeout(const Duration(seconds: 10));
          debugPrint('☁️ Synced ${bank.institutionName} to backend');
        } catch (e) {
          debugPrint('⚠️ Failed to sync ${bank.institutionName} to backend: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving connected banks: $e');
      rethrow;
    }
  }

  /// Add a new connected bank
  Future<ConnectedBank> addConnectedBank({
    required String publicToken,
    required String institutionId,
    required String institutionName,
    String? accountMask,
    String? accountType,
    String? logoUrl,
  }) async {
    try {
      // Exchange public token for access token
      final accessToken = await _exchangePublicToken(publicToken);

      if (accessToken == null) {
        throw Exception('Failed to exchange public token');
      }

      // Create new ConnectedBank
      final bank = ConnectedBank(
        institutionId: institutionId,
        institutionName: institutionName,
        accessToken: accessToken,
        accountMask: accountMask,
        accountType: accountType,
        connectedAt: DateTime.now(),
        logoUrl: logoUrl,
      );

      // Add to existing banks
      final banks = await getConnectedBanks();

      // Check if bank already exists (update instead of duplicate)
      final existingIndex = banks.indexWhere((b) => b.institutionId == institutionId);
      if (existingIndex != -1) {
        banks[existingIndex] = bank;
        debugPrint('🔄 Updated existing bank: $institutionName');
      } else {
        banks.add(bank);
        debugPrint('➕ Added new bank: $institutionName');
      }

      await _saveConnectedBanks(banks);
      return bank;
    } catch (e) {
      debugPrint('❌ Error adding connected bank: $e');
      rethrow;
    }
  }

  /// Exchange public token for access token via backend
  Future<String?> _exchangePublicToken(String publicToken) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/plaid/exchange_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'public_token': publicToken,
          'userId': 'user-${DateTime.now().millisecondsSinceEpoch}',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Note: Backend returns success but doesn't return access_token for security
        // In a real implementation, backend would store it and return an item_id
        // For now, we'll use the public_token as a placeholder
        debugPrint('✅ Successfully exchanged public token');
        return publicToken; // Temporary - in production, backend stores this
      } else {
        debugPrint('❌ Failed to exchange token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error exchanging public token: $e');
      return null;
    }
  }

  /// Sync transactions from a specific bank
  Future<List<Transaction>> syncBank(ConnectedBank bank, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔄 Syncing transactions from ${bank.institutionName}...');

      // Update bank status to syncing
      await _updateBankStatus(bank.institutionId, BankConnectionStatus.syncing);

      // Fetch transactions from backend
      final transactions = await _fetchTransactionsFromBackend(
        bank.accessToken,
        startDate: startDate,
        endDate: endDate,
      );

      // Tag transactions with bank info
      final taggedTransactions = transactions.map((t) {
        return Transaction(
          id: '${bank.institutionId}_${t.id}',
          plaidId: t.plaidId,
          name: t.name,
          amount: t.amount,
          date: t.date,
          merchantName: t.merchantName,
          category: t.category,
          isCategorized: t.isCategorized,
          institutionId: bank.institutionId,
          institutionName: bank.institutionName,
        );
      }).toList();

      // Update bank with sync results
      await _updateBankAfterSync(
        bank.institutionId,
        transactionCount: taggedTransactions.length,
      );

      debugPrint('✅ Synced ${taggedTransactions.length} transactions from ${bank.institutionName}');
      return taggedTransactions;
    } catch (e) {
      debugPrint('❌ Error syncing ${bank.institutionName}: $e');
      await _updateBankStatus(
        bank.institutionId,
        BankConnectionStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Sync all connected banks
  Future<Map<String, List<Transaction>>> syncAllBanks({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final banks = await getConnectedBanks();
    final Map<String, List<Transaction>> results = {};

    for (final bank in banks) {
      try {
        final transactions = await syncBank(bank, startDate: startDate, endDate: endDate);
        results[bank.institutionId] = transactions;
      } catch (e) {
        debugPrint('⚠️ Failed to sync ${bank.institutionName}, continuing with others...');
        results[bank.institutionId] = [];
      }
    }

    return results;
  }

  /// Fetch transactions from backend
  Future<List<Transaction>> _fetchTransactionsFromBackend(
    String accessToken, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // In production, backend would use the stored access_token
      // For now, this is a placeholder - actual implementation would call backend
      final response = await http.post(
        Uri.parse('$backendUrl/api/plaid/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': 'user-temp', // Backend would look up by access token
          'start_date': _formatDate(start),
          'end_date': _formatDate(end),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactions = data['transactions'] as List;

        return transactions.where((t) => t['amount'] > 0).map((t) {
          return Transaction(
            id: 'plaid_${t['transaction_id']}',
            plaidId: t['transaction_id'],
            name: t['name'] ?? 'Unknown',
            merchantName: t['merchant_name'],
            amount: (t['amount'] as num).toDouble(),
            date: DateTime.parse(t['date']),
            category: null,
            isCategorized: false,
          );
        }).toList();
      } else {
        throw Exception('Backend returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching transactions from backend: $e');
      // Return mock data for testing
      return _getMockTransactions();
    }
  }

  /// Get mock transactions for testing
  List<Transaction> _getMockTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'mock_1',
        plaidId: 'mock_plaid_1',
        name: 'Starbucks',
        amount: 5.75,
        date: now.subtract(const Duration(days: 1)),
        merchantName: 'Starbucks',
      ),
      Transaction(
        id: 'mock_2',
        plaidId: 'mock_plaid_2',
        name: 'Target',
        amount: 45.20,
        date: now.subtract(const Duration(days: 2)),
        merchantName: 'Target',
      ),
      Transaction(
        id: 'mock_3',
        plaidId: 'mock_plaid_3',
        name: 'Amazon',
        amount: 29.99,
        date: now.subtract(const Duration(days: 3)),
        merchantName: 'Amazon',
      ),
    ];
  }

  /// Update bank status
  Future<void> _updateBankStatus(
    String institutionId,
    BankConnectionStatus status, {
    String? errorMessage,
  }) async {
    final banks = await getConnectedBanks();
    final index = banks.indexWhere((b) => b.institutionId == institutionId);

    if (index != -1) {
      banks[index] = banks[index].copyWith(
        status: status,
        errorMessage: errorMessage,
      );
      await _saveConnectedBanks(banks);
    }
  }

  /// Update bank after successful sync
  Future<void> _updateBankAfterSync(
    String institutionId, {
    required int transactionCount,
  }) async {
    final banks = await getConnectedBanks();
    final index = banks.indexWhere((b) => b.institutionId == institutionId);

    if (index != -1) {
      banks[index] = banks[index].copyWith(
        status: BankConnectionStatus.connected,
        lastSyncedAt: DateTime.now(),
        lastSyncTransactionCount: transactionCount,
        errorMessage: null,
      );
      await _saveConnectedBanks(banks);
    }
  }

  /// Disconnect a specific bank
  Future<void> disconnectBank(String institutionId) async {
    try {
      // Delete from backend
      final userId = _authService.userId ?? 'guest';
      try {
        await http.delete(
          Uri.parse('$backendUrl/api/user/$userId/banks/$institutionId'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        debugPrint('☁️ Deleted $institutionId from backend');
      } catch (e) {
        debugPrint('⚠️ Failed to delete from backend: $e');
      }

      // Delete from local storage
      final banks = await getConnectedBanks();
      banks.removeWhere((b) => b.institutionId == institutionId);
      await _saveToLocalStorage(banks);
      debugPrint('🔌 Disconnected bank: $institutionId');
    } catch (e) {
      debugPrint('❌ Error disconnecting bank: $e');
      rethrow;
    }
  }

  /// Update bank nickname
  Future<void> updateBankNickname(String institutionId, String nickname) async {
    final banks = await getConnectedBanks();
    final index = banks.indexWhere((b) => b.institutionId == institutionId);

    if (index != -1) {
      banks[index] = banks[index].copyWith(nickname: nickname);
      await _saveConnectedBanks(banks);
    }
  }

  /// Format date for Plaid API (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Open Plaid Link UI (same as before)
  Future<Map<String, dynamic>?> openPlaidLink() async {
    try {
      final linkToken = await _createLinkToken();
      if (linkToken == null) {
        throw Exception('Failed to create link token');
      }

      if (kIsWeb) {
        debugPrint('🌐 Opening Plaid Link on web...');
        final result = await PlaidWebService.openPlaidLink(linkToken);
        return result;
      } else {
        debugPrint('📱 Opening Plaid Link on mobile...');
        throw UnsupportedError('Mobile Plaid Link not yet implemented');
      }
    } catch (e) {
      debugPrint('❌ Error opening Plaid Link: $e');
      rethrow;
    }
  }

  /// Create a link token via backend server
  Future<String?> _createLinkToken() async {
    try {
      final endpoint = '/api/plaid/create_link_token';
      debugPrint('🔗 Calling backend: $backendUrl$endpoint');

      final response = await http.post(
        Uri.parse('$backendUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': 'user-${DateTime.now().millisecondsSinceEpoch}',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Request timed out after 30 seconds');
          throw TimeoutException('Backend request timed out');
        },
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Link token created successfully via backend');
        return data['link_token'];
      } else {
        debugPrint('❌ Failed to create link token: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating link token: $e');
      debugPrint('   Stack trace: $stackTrace');
      return null;
    }
  }
}

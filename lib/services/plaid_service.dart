import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:plaid_flutter/plaid_flutter.dart';
import '../models/transaction.dart';

/// Service for managing Plaid integration
///
/// IMPORTANT: This is a demo implementation using Plaid Sandbox mode.
/// For production:
/// 1. Create a backend server to handle Plaid API calls
/// 2. Store credentials in environment variables on your backend
/// 3. Never expose your Plaid secret in client-side code
/// 4. Generate link tokens from your backend
class PlaidService {
  // Plaid configuration
  // TODO: Replace with your actual Plaid credentials from https://dashboard.plaid.com/
  static const String _clientId = 'YOUR_PLAID_CLIENT_ID_HERE';
  static const String _secret = 'YOUR_PLAID_SECRET_HERE';
  static const String _environment = 'sandbox'; // sandbox for testing

  PlaidLink? _plaidLink;
  String? _accessToken;
  String? _itemId;
  String? _linkedInstitutionName;

  /// Initialize Plaid Link
  Future<void> initializePlaidLink({
    required Function(String publicToken, LinkSuccessMetadata metadata) onSuccess,
    required Function(LinkError error, LinkErrorMetadata? metadata) onError,
    Function(LinkEvent event, LinkEventMetadata metadata)? onEvent,
  }) async {
    try {
      // In production, you should get the link token from your backend
      final linkToken = await _createLinkToken();

      if (linkToken == null) {
        throw Exception('Failed to create link token');
      }

      // Create Plaid Link configuration
      final configuration = LinkTokenConfiguration(
        token: linkToken,
      );

      // Initialize Plaid Link
      _plaidLink = PlaidLink(
        configuration: configuration,
        onSuccess: onSuccess,
        onError: onError,
        onEvent: onEvent,
      );

      debugPrint('✅ Plaid Link initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Plaid Link: $e');
      rethrow;
    }
  }

  /// Open Plaid Link UI
  Future<void> openPlaidLink() async {
    if (_plaidLink == null) {
      throw Exception('Plaid Link not initialized. Call initializePlaidLink first.');
    }

    await _plaidLink!.open();
  }

  /// Create a link token
  /// NOTE: In production, this MUST be done on your backend server
  Future<String?> _createLinkToken() async {
    try {
      // This is a demo - in production, call your backend API endpoint
      // Example: POST https://your-backend.com/api/plaid/create_link_token
      final response = await http.post(
        Uri.parse('https://sandbox.plaid.com/link/token/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': _clientId,
          'secret': _secret,
          'user': {
            'client_user_id': 'user-${DateTime.now().millisecondsSinceEpoch}',
          },
          'client_name': 'Swipe Finance',
          'products': ['transactions'],
          'country_codes': ['US'],
          'language': 'en',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['link_token'];
      } else {
        debugPrint('Failed to create link token: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating link token: $e');
      return null;
    }
  }

  /// Exchange public token for access token
  /// NOTE: In production, this MUST be done on your backend server
  Future<bool> exchangePublicToken(String publicToken) async {
    try {
      // This is a demo - in production, call your backend API endpoint
      // Example: POST https://your-backend.com/api/plaid/exchange_token
      final response = await http.post(
        Uri.parse('https://sandbox.plaid.com/item/public_token/exchange'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': _clientId,
          'secret': _secret,
          'public_token': publicToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _itemId = data['item_id'];

        debugPrint('✅ Successfully exchanged public token');
        debugPrint('   Access Token: ${_accessToken?.substring(0, 20)}...');
        return true;
      } else {
        debugPrint('Failed to exchange public token: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error exchanging public token: $e');
      return false;
    }
  }

  /// Fetch transactions from Plaid
  Future<List<Transaction>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_accessToken == null) {
      throw Exception('No access token. Link a bank account first.');
    }

    try {
      // Default to last 30 days if no dates provided
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await http.post(
        Uri.parse('https://sandbox.plaid.com/transactions/get'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': _clientId,
          'secret': _secret,
          'access_token': _accessToken,
          'start_date': _formatDate(start),
          'end_date': _formatDate(end),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactions = data['transactions'] as List;

        debugPrint('✅ Fetched ${transactions.length} transactions from Plaid');

        // Convert Plaid transactions to app Transaction model
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
        debugPrint('Failed to fetch transactions: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  /// Format date for Plaid API (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if bank account is linked
  bool get isLinked => _accessToken != null;

  /// Get access token (for debugging only)
  String? get accessToken => _accessToken;

  /// Get item ID
  String? get itemId => _itemId;

  /// Get linked institution name
  String? get linkedInstitutionName => _linkedInstitutionName;

  /// Set linked institution name
  set linkedInstitutionName(String? name) {
    _linkedInstitutionName = name;
  }

  /// Disconnect bank account
  void disconnect() {
    _accessToken = null;
    _itemId = null;
    _linkedInstitutionName = null;
    debugPrint('🔌 Disconnected from Plaid');
  }

  /// Check if Plaid is initialized
  bool get isInitialized => _plaidLink != null;
}

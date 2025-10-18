import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart' show debugPrint;

/// Web-specific Plaid Link implementation using JavaScript interop
class PlaidWebService {
  /// Open Plaid Link on web using JavaScript SDK
  static Future<Map<String, dynamic>?> openPlaidLink(String linkToken) async {
    debugPrint('🌐 Opening Plaid Link on web...');

    try {
      // Create a completer to handle async callback
      final result = await _openPlaidLinkJS(linkToken);
      return result;
    } catch (e) {
      debugPrint('❌ Error opening Plaid Link: $e');
      return null;
    }
  }

  /// JavaScript interop to open Plaid Link
  static Future<Map<String, dynamic>?> _openPlaidLinkJS(String linkToken) async {
    return Future<Map<String, dynamic>?>(() {
      Map<String, dynamic>? result;

      // Create Plaid Link handler configuration
      final config = js_util.jsify({
        'token': linkToken,
        'onSuccess': js.allowInterop((publicToken, metadata) {
          debugPrint('✅ Plaid Link Success!');
          debugPrint('   Public Token: ${publicToken.toString().substring(0, 20)}...');

          result = {
            'publicToken': publicToken.toString(),
            'metadata': {
              'institution': {
                'name': js_util.getProperty(js_util.getProperty(metadata, 'institution'), 'name'),
                'institution_id': js_util.getProperty(js_util.getProperty(metadata, 'institution'), 'institution_id'),
              },
              'accounts': _extractAccounts(metadata),
            },
          };
        }),
        'onExit': js.allowInterop((error, metadata) {
          if (error != null) {
            debugPrint('❌ Plaid Link Error: ${js_util.getProperty(error, 'error_message')}');
          } else {
            debugPrint('ℹ️  Plaid Link closed by user');
          }
          result = null;
        }),
      });

      // Create Plaid Link handler
      final handler = js_util.callMethod(
        js.context['Plaid'],
        'create',
        [config],
      );

      // Open Plaid Link
      js_util.callMethod(handler, 'open', []);

      // Wait for result (polling approach)
      return Future.delayed(const Duration(seconds: 1), () => result);
    });
  }

  /// Extract accounts from metadata
  static List<Map<String, dynamic>> _extractAccounts(dynamic metadata) {
    try {
      final accountsJS = js_util.getProperty(metadata, 'accounts');
      if (accountsJS == null) return [];

      final accountsList = <Map<String, dynamic>>[];
      final length = js_util.getProperty(accountsJS, 'length') as int;

      for (var i = 0; i < length; i++) {
        final account = js_util.getProperty(accountsJS, i.toString());
        accountsList.add({
          'id': js_util.getProperty(account, 'id'),
          'name': js_util.getProperty(account, 'name'),
          'mask': js_util.getProperty(account, 'mask'),
          'type': js_util.getProperty(account, 'type'),
          'subtype': js_util.getProperty(account, 'subtype'),
        });
      }

      return accountsList;
    } catch (e) {
      debugPrint('⚠️  Error extracting accounts: $e');
      return [];
    }
  }
}

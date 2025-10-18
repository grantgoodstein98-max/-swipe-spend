import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show debugPrint;

/// Web-specific Plaid Link implementation using iframe and postMessage
class PlaidWebService {
  static html.IFrameElement? _iframe;
  static Completer<Map<String, dynamic>?>? _completer;
  static StreamSubscription? _messageSubscription;

  /// Open Plaid Link on web using iframe approach
  static Future<Map<String, dynamic>?> openPlaidLink(String linkToken) async {
    debugPrint('🌐 Opening Plaid Link via iframe...');

    try {
      // Clean up any existing iframe/listeners
      _cleanup();

      // Create completer for async result
      _completer = Completer<Map<String, dynamic>?>();

      // Create iframe element
      _iframe = html.IFrameElement()
        ..src = 'plaid_link.html'
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.zIndex = '9999'
        ..style.background = 'rgba(0, 0, 0, 0.5)';

      // Add iframe to body
      html.document.body?.append(_iframe!);
      debugPrint('✅ Iframe created and added to DOM');

      // Set up message listener
      _messageSubscription = html.window.onMessage.listen((event) {
        final data = event.data;
        debugPrint('📨 Received message from iframe: $data');

        if (data is Map) {
          final type = data['type'];

          switch (type) {
            case 'PLAID_READY':
              debugPrint('✅ Plaid iframe is ready, sending link token');
              // Send link token to iframe
              _iframe?.contentWindow?.postMessage({
                'type': 'OPEN_PLAID_LINK',
                'linkToken': linkToken,
              }, '*');
              break;

            case 'PLAID_SUCCESS':
              debugPrint('✅ Plaid Link success!');
              final publicToken = data['publicToken'];
              final metadata = data['metadata'];

              if (!_completer!.isCompleted) {
                _completer!.complete({
                  'publicToken': publicToken,
                  'metadata': metadata,
                });
              }
              _cleanup();
              break;

            case 'PLAID_ERROR':
              debugPrint('❌ Plaid Link error: ${data['error']}');
              if (!_completer!.isCompleted) {
                _completer!.completeError(Exception(data['error']));
              }
              _cleanup();
              break;

            case 'PLAID_EXIT':
              debugPrint('ℹ️  Plaid Link closed by user');
              if (!_completer!.isCompleted) {
                _completer!.complete(null);
              }
              _cleanup();
              break;
          }
        }
      });

      // Wait for result with timeout
      return await _completer!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('⏱️  Plaid Link timeout');
          _cleanup();
          throw TimeoutException('Plaid Link timeout');
        },
      );
    } catch (e) {
      debugPrint('❌ Error in openPlaidLink: $e');
      _cleanup();
      rethrow;
    }
  }

  /// Clean up iframe and listeners
  static void _cleanup() {
    debugPrint('🧹 Cleaning up Plaid iframe');

    _messageSubscription?.cancel();
    _messageSubscription = null;

    _iframe?.remove();
    _iframe = null;

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(null);
    }
    _completer = null;
  }
}

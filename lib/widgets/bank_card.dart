import 'package:flutter/material.dart';
import '../models/connected_bank.dart';

/// Card widget displaying a connected bank with sync controls
class BankCard extends StatelessWidget {
  final ConnectedBank bank;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;
  final VoidCallback? onReconnect;
  final VoidCallback? onViewTransactions;
  final bool isSyncing;

  const BankCard({
    super.key,
    required this.bank,
    required this.onSync,
    required this.onDisconnect,
    this.onReconnect,
    this.onViewTransactions,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(
                color: const Color(0xFF38383A).withOpacity(0.5),
                width: 0.5,
              )
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank header with icon, name, and menu
            Row(
              children: [
                // Bank icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(bank.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: _getStatusColor(bank.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Bank name and account info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.displayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildAccountSubtitle(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overflow menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'sync':
                        onSync();
                        break;
                      case 'view':
                        onViewTransactions?.call();
                        break;
                      case 'reconnect':
                        onReconnect?.call();
                        break;
                      case 'disconnect':
                        _showDisconnectDialog(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sync',
                      child: Row(
                        children: [
                          Icon(Icons.sync, size: 20),
                          SizedBox(width: 12),
                          Text('Sync Now'),
                        ],
                      ),
                    ),
                    if (onViewTransactions != null)
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long, size: 20),
                            SizedBox(width: 12),
                            Text('View Transactions'),
                          ],
                        ),
                      ),
                    if (bank.status == BankConnectionStatus.needsReauth && onReconnect != null)
                      const PopupMenuItem(
                        value: 'reconnect',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: 12),
                            Text('Reconnect'),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Disconnect', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status badge and last sync
            Row(
              children: [
                _buildStatusBadge(theme),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  bank.lastSyncText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Sync button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSyncing ? null : onSync,
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: Text(
                  isSyncing ? 'Syncing...' : 'Sync ${bank.displayName}',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _getStatusColor(bank.status),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildAccountSubtitle() {
    final parts = <String>[];
    if (bank.accountType != null) {
      parts.add(bank.accountType!);
    }
    if (bank.accountMask != null) {
      parts.add('••••  ${bank.accountMask}');
    }
    return parts.isEmpty ? 'Bank Account' : parts.join(' • ');
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final status = isSyncing ? BankConnectionStatus.syncing : bank.status;
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BankConnectionStatus status) {
    switch (status) {
      case BankConnectionStatus.connected:
        return Colors.green;
      case BankConnectionStatus.needsReauth:
        return Colors.orange;
      case BankConnectionStatus.error:
        return Colors.red;
      case BankConnectionStatus.syncing:
        return Colors.blue;
    }
  }

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Bank?'),
        content: Text(
          'Are you sure you want to disconnect ${bank.displayName}?\n\n'
          'Your existing transactions will remain, but future syncs will stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDisconnect();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

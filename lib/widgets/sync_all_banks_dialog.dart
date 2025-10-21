import 'package:flutter/material.dart';
import '../models/connected_bank.dart';

/// Dialog showing progress of syncing multiple banks
class SyncAllBanksDialog extends StatefulWidget {
  final List<ConnectedBank> banks;
  final Future<Map<String, int>> Function() onSync;

  const SyncAllBanksDialog({
    super.key,
    required this.banks,
    required this.onSync,
  });

  @override
  State<SyncAllBanksDialog> createState() => _SyncAllBanksDialogState();
}

class _SyncAllBanksDialogState extends State<SyncAllBanksDialog> {
  final Map<String, SyncStatus> _bankStatuses = {};
  bool _isComplete = false;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    // Initialize all banks as waiting
    for (final bank in widget.banks) {
      _bankStatuses[bank.institutionId] = SyncStatus.waiting;
    }
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      final results = await widget.onSync();

      // Update statuses based on results
      setState(() {
        for (final entry in results.entries) {
          _bankStatuses[entry.key] = SyncStatus.success;
          _totalTransactions += entry.value;
        }
        _isComplete = true;
      });
    } catch (e) {
      setState(() {
        // Mark all as error if the whole sync fails
        for (final key in _bankStatuses.keys) {
          if (_bankStatuses[key] == SyncStatus.waiting ||
              _bankStatuses[key] == SyncStatus.syncing) {
            _bankStatuses[key] = SyncStatus.error;
          }
        }
        _isComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successCount = _bankStatuses.values.where((s) => s == SyncStatus.success).length;

    return AlertDialog(
      title: Row(
        children: [
          if (!_isComplete)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              successCount == widget.banks.length
                  ? Icons.check_circle
                  : Icons.warning,
              color: successCount == widget.banks.length
                  ? Colors.green
                  : Colors.orange,
            ),
          const SizedBox(width: 12),
          Text(
            _isComplete ? 'Sync Complete' : 'Syncing Banks...',
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress summary
            if (!_isComplete)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Syncing ${_bankStatuses.values.where((s) => s == SyncStatus.success).length}/${widget.banks.length} banks',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),

            // Bank list with status
            ...widget.banks.map((bank) {
              final status = _bankStatuses[bank.institutionId] ?? SyncStatus.waiting;
              return _buildBankStatusRow(bank, status, theme);
            }),

            // Final summary
            if (_isComplete) ...[
              const Divider(height: 32),
              _buildSummary(theme, successCount),
            ],
          ],
        ),
      ),
      actions: [
        if (_isComplete)
          TextButton(
            onPressed: () => Navigator.pop(context, _totalTransactions),
            child: const Text('Done'),
          ),
      ],
    );
  }

  Widget _buildBankStatusRow(ConnectedBank bank, SyncStatus status, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Status icon
          SizedBox(
            width: 24,
            height: 24,
            child: _buildStatusIcon(status),
          ),
          const SizedBox(width: 12),

          // Bank name
          Expanded(
            child: Text(
              bank.displayName,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Transaction count or status
          if (status == SyncStatus.success && _isComplete)
            Text(
              '${_getTransactionCount(bank.institutionId)} txns',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (status == SyncStatus.error)
            const Icon(Icons.error_outline, size: 20, color: Colors.red)
          else
            const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.waiting:
        return Icon(Icons.schedule, size: 20, color: Colors.grey[400]);
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.success:
        return const Icon(Icons.check_circle, size: 20, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.error, size: 20, color: Colors.red);
    }
  }

  Widget _buildSummary(ThemeData theme, int successCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Banks Synced:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$successCount/${widget.banks.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Transactions:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_totalTransactions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getTransactionCount(String institutionId) {
    // This would come from the sync results
    // For now, return a placeholder
    return 0;
  }
}

enum SyncStatus {
  waiting,
  syncing,
  success,
  error,
}

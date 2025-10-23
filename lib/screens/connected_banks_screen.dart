import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plaid_provider_multi_bank.dart';
import '../providers/transaction_provider.dart';
import '../widgets/bank_card.dart';
import '../widgets/sync_all_banks_dialog.dart';
import '../models/connected_bank.dart';

/// Screen displaying all connected banks with sync controls
class ConnectedBanksScreen extends StatefulWidget {
  const ConnectedBanksScreen({super.key});

  @override
  State<ConnectedBanksScreen> createState() => _ConnectedBanksScreenState();
}

class _ConnectedBanksScreenState extends State<ConnectedBanksScreen> {
  @override
  void initState() {
    super.initState();
    // Load connected banks on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaidProviderMultiBank>().loadConnectedBanks();
    });
  }

  Future<void> _syncBank(BuildContext context, ConnectedBank bank) async {
    final plaidProvider = context.read<PlaidProviderMultiBank>();
    final transactionProvider = context.read<TransactionProvider>();

    try {
      final transactions = await plaidProvider.syncBank(bank.institutionId);

      if (transactions.isNotEmpty && mounted) {
        // Import transactions
        final imported = await transactionProvider.importTransactions(transactions);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Imported $imported new transaction${imported != 1 ? 's' : ''} from ${bank.displayName}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No new transactions from ${bank.displayName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to sync ${bank.displayName}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _syncAllBanks(BuildContext context) async {
    final plaidProvider = context.read<PlaidProviderMultiBank>();
    final transactionProvider = context.read<TransactionProvider>();
    final banks = plaidProvider.connectedBanks;

    if (banks.isEmpty) return;

    // Show sync dialog
    final totalImported = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncAllBanksDialog(
        banks: banks,
        onSync: () async {
          final results = await plaidProvider.syncAllBanks();
          final counts = <String, int>{};

          // Import transactions from all banks
          for (final entry in results.entries) {
            if (entry.value.isNotEmpty) {
              final imported = await transactionProvider.importTransactions(entry.value);
              counts[entry.key] = imported;
            } else {
              counts[entry.key] = 0;
            }
          }

          return counts;
        },
      ),
    );

    if (totalImported != null && totalImported > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Synced ${banks.length} banks • Imported $totalImported total transactions',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _disconnectBank(BuildContext context, ConnectedBank bank) async {
    final plaidProvider = context.read<PlaidProviderMultiBank>();

    try {
      await plaidProvider.disconnectBank(bank.institutionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnected from ${bank.displayName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connected Banks',
          style: theme.textTheme.displayLarge,
        ),
      ),
      body: Consumer<PlaidProviderMultiBank>(
        builder: (context, plaidProvider, child) {
          if (plaidProvider.isLoading && plaidProvider.connectedBanks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final banks = plaidProvider.connectedBanks;

          if (banks.isEmpty) {
            return _buildEmptyState(context, theme, isDark, plaidProvider);
          }

          return RefreshIndicator(
            onRefresh: () => plaidProvider.loadConnectedBanks(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Header with bank count
                Text(
                  '${banks.length} Bank${banks.length != 1 ? 's' : ''} Connected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons row
                Row(
                  children: [
                    // Add Another Bank button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => plaidProvider.connectBankAccount(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Bank'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.colorScheme.primary),
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Sync All Banks button (only if 2+ banks)
                    if (banks.length >= 2) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _syncAllBanks(context),
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync All'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Bank cards
                ...banks.map((bank) {
                  return BankCard(
                    bank: bank,
                    onSync: () => _syncBank(context, bank),
                    onDisconnect: () => _disconnectBank(context, bank),
                    isSyncing: plaidProvider.isBankSyncing(bank.institutionId),
                  );
                }),

                const SizedBox(height: 16),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'New transactions will appear in the Swipe tab after syncing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    PlaidProviderMultiBank plaidProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Banks Connected',
              style: theme.textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your bank to automatically import transactions',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => plaidProvider.connectBankAccount(context),
              icon: const Icon(Icons.add_link),
              label: const Text('Connect Bank'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

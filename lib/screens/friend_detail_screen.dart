import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/friend.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

class FriendDetailScreen extends StatefulWidget {
  final Friend friend;

  const FriendDetailScreen({super.key, required this.friend});

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  List<Transaction> _transactions = [];
  bool _loading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
  final _dateFormat = DateFormat('d MMM yyyy', 'it_IT');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final provider = context.read<AppProvider>();
    final transactions =
        await provider.getTransactionsForFriend(widget.friend.id);
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final balance = provider.balanceFor(widget.friend.id);
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, balance),
              if (_loading)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (_transactions.isEmpty)
                _buildEmptyState()
              else
                _buildTransactionList(context, provider),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddTransaction(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuova transazione'),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, double balance) {
    final isPositive = balance >= 0;
    final balanceColor = balance == 0
        ? Colors.grey
        : isPositive
            ? Colors.green
            : Colors.red;

    return SliverAppBar.large(
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: widget.friend.avatarColor,
            radius: 16,
            child: Text(widget.friend.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Text(widget.friend.name),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _BalanceChip(
            balance: balance,
            format: _currencyFormat,
            color: balanceColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nessuna transazione',
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Aggiungi un debito o un credito',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, AppProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final t = _transactions[index];
            return _TransactionTile(
              transaction: t,
              currencyFormat: _currencyFormat,
              dateFormat: _dateFormat,
              onDelete: () => _deleteTransaction(context, t, provider),
            );
          },
          childCount: _transactions.length,
        ),
      ),
    );
  }

  Future<void> _openAddTransaction(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(friend: widget.friend),
      ),
    );
    _loadTransactions();
  }

  Future<void> _deleteTransaction(
      BuildContext context, Transaction t, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina transazione'),
        content: const Text('Sei sicuro di voler eliminare questa transazione?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteTransaction(t.id, t.friendId, t.signedAmount);
      _loadTransactions();
    }
  }
}

class _BalanceChip extends StatelessWidget {
  final double balance;
  final NumberFormat format;
  final Color color;

  const _BalanceChip(
      {required this.balance, required this.format, required this.color});

  @override
  Widget build(BuildContext context) {
    final abs = balance.abs();
    String label;
    if (balance == 0) {
      label = 'Siete in pari';
    } else if (balance > 0) {
      label = 'Ti deve ${format.format(abs)}';
    } else {
      label = 'Gli devi ${format.format(abs)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            balance > 0
                ? Icons.arrow_circle_down_outlined
                : balance < 0
                    ? Icons.arrow_circle_up_outlined
                    : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description.isEmpty
                        ? (isCredit ? 'Credito' : 'Debito')
                        : transaction.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(transaction.date),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close,
                      size: 18, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

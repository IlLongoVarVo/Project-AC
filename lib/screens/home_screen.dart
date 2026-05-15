import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/friend.dart';
import 'friend_detail_screen.dart';
import 'add_friend_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, provider),
              if (provider.friends.isEmpty)
                _buildEmptyState()
              else
                _buildFriendList(context, provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFriend(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Aggiungi amico'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar.large(
      title: const Text('I miei debiti'),
      backgroundColor: colorScheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showSummaryDialog(context, provider),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: _SummaryBanner(
          credit: provider.totalCredit,
          debt: provider.totalDebt,
          format: _currencyFormat,
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
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Nessun amico aggiunto',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tocca "Aggiungi amico" per iniziare',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendList(BuildContext context, AppProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _FriendTile(
            friend: provider.friends[index],
            balance: provider.balanceFor(provider.friends[index].id),
            format: _currencyFormat,
            onTap: () => _openFriendDetail(context, provider.friends[index]),
            onDelete: () => _confirmDeleteFriend(context, provider.friends[index], provider),
          ),
          childCount: provider.friends.length,
        ),
      ),
    );
  }

  void _openAddFriend(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddFriendScreen()));
  }

  void _openFriendDetail(BuildContext context, Friend friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FriendDetailScreen(friend: friend)),
    );
  }

  Future<void> _confirmDeleteFriend(
      BuildContext context, Friend friend, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina amico'),
        content: Text(
            'Vuoi eliminare ${friend.name}? Tutte le transazioni saranno cancellate.'),
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
      await provider.deleteFriend(friend.id);
    }
  }

  void _showSummaryDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Riepilogo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
                label: 'Ti devono',
                amount: provider.totalCredit,
                color: Colors.green),
            const SizedBox(height: 8),
            _SummaryRow(
                label: 'Devi tu',
                amount: provider.totalDebt,
                color: Colors.red),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Bilancio netto',
              amount: (provider.totalCredit - provider.totalDebt).abs(),
              color: provider.totalCredit >= provider.totalDebt
                  ? Colors.green
                  : Colors.red,
              prefix: provider.totalCredit >= provider.totalDebt ? '+' : '-',
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi')),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final double credit;
  final double debt;
  final NumberFormat format;

  const _SummaryBanner(
      {required this.credit, required this.debt, required this.format});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Ti devono',
              amount: format.format(credit),
              color: Colors.green,
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'Devi tu',
              amount: format.format(debt),
              color: Colors.red,
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500)),
                Text(amount,
                    style: TextStyle(
                        fontSize: 15,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  final double balance;
  final NumberFormat format;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FriendTile({
    required this.friend,
    required this.balance,
    required this.format,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    final absBalance = balance.abs();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: friend.avatarColor,
                radius: 22,
                child: Text(friend.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      balance == 0
                          ? 'In pari'
                          : isPositive
                              ? 'Ti deve ${format.format(absBalance)}'
                              : 'Gli devi ${format.format(absBalance)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: balance == 0
                              ? Colors.grey
                              : balanceColor),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    balance == 0
                        ? '€ 0,00'
                        : '${isPositive ? '+' : '-'}${format.format(absBalance)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: balance == 0 ? Colors.grey : balanceColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.grey.shade400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String prefix;

  const _SummaryRow(
      {required this.label,
      required this.amount,
      required this.color,
      this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(
          '$prefix${format.format(amount)}',
          style: TextStyle(
              fontSize: 15, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

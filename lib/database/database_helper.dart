import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static const _friendsBox = 'friends';
  static const _transactionsBox = 'transactions';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_friendsBox);
    await Hive.openBox<Map>(_transactionsBox);
  }

  Box<Map> get _friends => Hive.box<Map>(_friendsBox);
  Box<Map> get _transactions => Hive.box<Map>(_transactionsBox);

  // ── Friends ────────────────────────────────────────────────────────────────

  List<Friend> getFriends() {
    final friends = _friends.values
        .map((m) => Friend.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    friends.sort((a, b) => a.name.compareTo(b.name));
    return friends;
  }

  Future<void> insertFriend(Friend friend) =>
      _friends.put(friend.id, friend.toMap());

  Future<void> updateFriend(Friend friend) =>
      _friends.put(friend.id, friend.toMap());

  Future<void> deleteFriend(String id) async {
    await _friends.delete(id);
    final toDelete = _transactions.keys
        .where((k) {
          final t = _transactions.get(k);
          return t != null && t['friendId'] == id;
        })
        .toList();
    for (final k in toDelete) {
      await _transactions.delete(k);
    }
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  List<Transaction> getTransactionsForFriend(String friendId) {
    final txs = _transactions.values
        .map((m) => Transaction.fromMap(Map<String, dynamic>.from(m)))
        .where((t) => t.friendId == friendId)
        .toList();
    txs.sort((a, b) => b.date.compareTo(a.date));
    return txs;
  }

  double getBalanceForFriend(String friendId) =>
      getTransactionsForFriend(friendId)
          .fold(0.0, (sum, t) => sum + t.signedAmount);

  Map<String, double> getAllBalances() {
    final Map<String, double> balances = {};
    for (final m in _transactions.values) {
      final t = Transaction.fromMap(Map<String, dynamic>.from(m));
      balances[t.friendId] = (balances[t.friendId] ?? 0.0) + t.signedAmount;
    }
    return balances;
  }

  Future<void> insertTransaction(Transaction transaction) =>
      _transactions.put(transaction.id, transaction.toMap());

  Future<void> deleteTransaction(String id) => _transactions.delete(id);
}

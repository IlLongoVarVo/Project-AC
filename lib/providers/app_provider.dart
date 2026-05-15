import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/friend.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class AppProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<Friend> _friends = [];
  Map<String, double> _balances = {};
  bool _isLoading = false;

  List<Friend> get friends => _friends;
  Map<String, double> get balances => _balances;
  bool get isLoading => _isLoading;

  double get totalCredit => _balances.values
      .where((b) => b > 0)
      .fold(0.0, (sum, b) => sum + b);

  double get totalDebt => _balances.values
      .where((b) => b < 0)
      .fold(0.0, (sum, b) => sum + b.abs());

  double balanceFor(String friendId) => _balances[friendId] ?? 0.0;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    _friends = _db.getFriends();
    _balances = _db.getAllBalances();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFriend(String name, Color color) async {
    final friend = Friend(
      id: _uuid.v4(),
      name: name.trim(),
      avatarColorValue: color.toARGB32(),
    );
    await _db.insertFriend(friend);
    _friends.add(friend);
    _friends.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateFriend(Friend friend) async {
    await _db.updateFriend(friend);
    final idx = _friends.indexWhere((f) => f.id == friend.id);
    if (idx != -1) _friends[idx] = friend;
    _friends.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteFriend(String friendId) async {
    await _db.deleteFriend(friendId);
    _friends.removeWhere((f) => f.id == friendId);
    _balances.remove(friendId);
    notifyListeners();
  }

  List<Transaction> getTransactionsForFriend(String friendId) =>
      _db.getTransactionsForFriend(friendId);

  Future<void> addTransaction({
    required String friendId,
    required double amount,
    required TransactionType type,
    required String description,
    required DateTime date,
  }) async {
    final transaction = Transaction(
      id: _uuid.v4(),
      friendId: friendId,
      amount: amount,
      type: type,
      description: description,
      date: date,
    );
    await _db.insertTransaction(transaction);
    _balances[friendId] =
        (_balances[friendId] ?? 0.0) + transaction.signedAmount;
    notifyListeners();
  }

  Future<void> deleteTransaction(
      String transactionId, String friendId, double signedAmount) async {
    await _db.deleteTransaction(transactionId);
    _balances[friendId] = (_balances[friendId] ?? 0.0) - signedAmount;
    notifyListeners();
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/friend.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'friend_debt_tracker.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE friends (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarColorValue INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        friendId TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (friendId) REFERENCES friends(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Friends ────────────────────────────────────────────────────────────────

  Future<List<Friend>> getFriends() async {
    final db = await database;
    final rows = await db.query('friends', orderBy: 'name ASC');
    return rows.map(Friend.fromMap).toList();
  }

  Future<void> insertFriend(Friend friend) async {
    final db = await database;
    await db.insert('friends', friend.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFriend(Friend friend) async {
    final db = await database;
    await db.update('friends', friend.toMap(),
        where: 'id = ?', whereArgs: [friend.id]);
  }

  Future<void> deleteFriend(String id) async {
    final db = await database;
    await db.delete('friends', where: 'id = ?', whereArgs: [id]);
    await db.delete('transactions', where: 'friendId = ?', whereArgs: [id]);
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<List<Transaction>> getTransactionsForFriend(String friendId) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'friendId = ?',
      whereArgs: [friendId],
      orderBy: 'date DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<double> getBalanceForFriend(String friendId) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'friendId = ?',
      whereArgs: [friendId],
    );
    return rows
        .map(Transaction.fromMap)
        .fold(0.0, (sum, t) => sum + t.signedAmount);
  }

  Future<Map<String, double>> getAllBalances() async {
    final db = await database;
    final rows = await db.query('transactions');
    final Map<String, double> balances = {};
    for (final t in rows.map(Transaction.fromMap)) {
      balances[t.friendId] = (balances[t.friendId] ?? 0.0) + t.signedAmount;
    }
    return balances;
  }

  Future<void> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}

enum TransactionType { credit, debt }

class Transaction {
  final String id;
  final String friendId;
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime date;

  const Transaction({
    required this.id,
    required this.friendId,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
  });

  /// Positive = they owe you (credit), Negative = you owe them (debt)
  double get signedAmount =>
      type == TransactionType.credit ? amount : -amount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'friendId': friendId,
        'amount': amount,
        'type': type.name,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        friendId: map['friendId'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: TransactionType.values.byName(map['type'] as String),
        description: map['description'] as String,
        date: DateTime.parse(map['date'] as String),
      );
}

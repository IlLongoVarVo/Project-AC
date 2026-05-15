import 'package:flutter_test/flutter_test.dart';
import 'package:friend_debt_tracker/models/friend.dart';
import 'package:friend_debt_tracker/models/transaction.dart';

void main() {
  group('Friend', () {
    test('initials from two-word name', () {
      const f = Friend(id: '1', name: 'Mario Rossi', avatarColorValue: 0xFF5C6BC0);
      expect(f.initials, 'MR');
    });

    test('initials from single name', () {
      const f = Friend(id: '1', name: 'mario', avatarColorValue: 0xFF5C6BC0);
      expect(f.initials, 'M');
    });

    test('serialization round-trip', () {
      const original = Friend(id: 'abc', name: 'Luca Bianchi', avatarColorValue: 0xFF42A5F5);
      final restored = Friend.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.avatarColorValue, original.avatarColorValue);
    });
  });

  group('Transaction', () {
    test('credit has positive signedAmount', () {
      final t = Transaction(
        id: '1', friendId: 'f1', amount: 50.0,
        type: TransactionType.credit, description: 'cena',
        date: DateTime(2025, 1, 1),
      );
      expect(t.signedAmount, 50.0);
    });

    test('debt has negative signedAmount', () {
      final t = Transaction(
        id: '2', friendId: 'f1', amount: 30.0,
        type: TransactionType.debt, description: 'benzina',
        date: DateTime(2025, 1, 2),
      );
      expect(t.signedAmount, -30.0);
    });

    test('serialization round-trip', () {
      final original = Transaction(
        id: 'xyz', friendId: 'f1', amount: 12.50,
        type: TransactionType.credit, description: 'caffè',
        date: DateTime(2025, 6, 15),
      );
      final restored = Transaction.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.type, original.type);
      expect(restored.description, original.description);
    });
  });
}

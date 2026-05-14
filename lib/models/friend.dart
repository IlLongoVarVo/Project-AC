import 'package:flutter/material.dart';

class Friend {
  final String id;
  final String name;
  final int avatarColorValue;

  const Friend({
    required this.id,
    required this.name,
    required this.avatarColorValue,
  });

  Color get avatarColor => Color(avatarColorValue);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarColorValue': avatarColorValue,
      };

  factory Friend.fromMap(Map<String, dynamic> map) => Friend(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarColorValue: map['avatarColorValue'] as int,
      );

  Friend copyWith({String? name, int? avatarColorValue}) => Friend(
        id: id,
        name: name ?? this.name,
        avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      );
}

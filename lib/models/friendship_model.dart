// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  final String uid1;
  final String uid2;
  final Timestamp createdAt;
  Friendship({
    required this.uid1,
    required this.uid2,
    required this.createdAt,
  });

  Friendship copyWith({
    String? uid1,
    String? uid2,
    Timestamp? createdAt,
  }) {
    return Friendship(
      uid1: uid1 ?? this.uid1,
      uid2: uid2 ?? this.uid2,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid1': uid1,
      'uid2': uid2,
      'createdAt': createdAt,
    };
  }

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      uid1: map['uid1'] as String,
      uid2: map['uid2'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Friendship.fromJson(String source) =>
      Friendship.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Friendship(uid1: $uid1, uid2: $uid2, createdAt: $createdAt)';

  @override
  bool operator ==(covariant Friendship other) {
    if (identical(this, other)) return true;

    return other.uid1 == uid1 &&
        other.uid2 == uid2 &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => uid1.hashCode ^ uid2.hashCode ^ createdAt.hashCode;
}

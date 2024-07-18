// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Follower {
  final String id;
  final String followerUid;
  final String targetUid;
  final Timestamp createdAt;
  Follower({
    required this.id,
    required this.followerUid,
    required this.targetUid,
    required this.createdAt,
  });

  Follower copyWith({
    String? id,
    String? followerUid,
    String? targetUid,
    Timestamp? createdAt,
  }) {
    return Follower(
      id: id ?? this.id,
      followerUid: followerUid ?? this.followerUid,
      targetUid: targetUid ?? this.targetUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'followerUid': followerUid,
      'targetUid': targetUid,
      'createdAt': createdAt,
    };
  }

  factory Follower.fromMap(Map<String, dynamic> map) {
    return Follower(
      id: map['id'] as String,
      followerUid: map['followerUid'] as String,
      targetUid: map['targetUid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Follower.fromJson(String source) =>
      Follower.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Follower(id: $id, followerUid: $followerUid, targetUid: $targetUid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Follower other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.followerUid == followerUid &&
      other.targetUid == targetUid &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      followerUid.hashCode ^
      targetUid.hashCode ^
      createdAt.hashCode;
  }
}

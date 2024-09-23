import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class BlockModel {
  final String id;
  final String uid;
  final String blockUid;
  final Timestamp createdAt;

  BlockModel({
    required this.id,
    required this.uid,
    required this.blockUid,
    required this.createdAt,
  });

  BlockModel copyWith({
    String? id,
    String? uid,
    String? blockUid,
    Timestamp? createdAt,
  }) {
    return BlockModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      blockUid: blockUid ?? this.blockUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'blockUid': blockUid,
      'createdAt': createdAt,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      blockUid: map['blockUid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory BlockModel.fromJson(String source) =>
      BlockModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Block(id: $id, uid: $uid, blockUid: $blockUid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant BlockModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.uid == uid &&
        other.blockUid == blockUid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ uid.hashCode ^ blockUid.hashCode ^ createdAt.hashCode;
  }
}

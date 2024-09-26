import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String uid;
  final String communityId;
  final String question;
  final Timestamp createdAt;

  Poll({
    required this.id,
    required this.uid,
    required this.communityId,
    required this.question,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'communityId': communityId,
      'question': question,
      'createdAt': createdAt,
    };
  }

  factory Poll.fromMap(Map<String, dynamic> map) {
    return Poll(
      id: map['id'] as String,
      uid: map['uid'] as String,
      communityId: map['communityId'] as String,
      question: map['question'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Poll copyWith({
    String? id,
    String? uid,
    String? communityId,
    String? question,
    Timestamp? createdAt,
  }) {
    return Poll(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      communityId: communityId ?? this.communityId,
      question: question ?? this.question,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String toJson() => json.encode(toMap());

  factory Poll.fromJson(String source) =>
      Poll.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Poll(id: $id, uid: $uid, communityId: $communityId, question: $question, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Poll other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.communityId == communityId &&
        other.question == question &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        communityId.hashCode ^
        question.hashCode ^
        createdAt.hashCode;
  }
}

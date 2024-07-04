// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class PostUpvote {
  final String id;
  final String postId;
  final String uid;
  final Timestamp createdAt;
  PostUpvote({
    required this.id,
    required this.postId,
    required this.uid,
    required this.createdAt,
  });

  PostUpvote copyWith({
    String? id,
    String? postId,
    String? uid,
    Timestamp? createdAt,
  }) {
    return PostUpvote(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'postId': postId,
      'uid': uid,
      'createdAt': createdAt,
    };
  }

  factory PostUpvote.fromMap(Map<String, dynamic> map) {
    return PostUpvote(
      id: map['id'] as String,
      postId: map['postId'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory PostUpvote.fromJson(String source) =>
      PostUpvote.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PostUpvote(id: $id, postId: $postId, uid: $uid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant PostUpvote other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.postId == postId &&
        other.uid == uid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ postId.hashCode ^ uid.hashCode ^ createdAt.hashCode;
  }
}

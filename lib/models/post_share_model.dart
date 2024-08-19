import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class PostShare {
  final String id;
  final String postId;
  final String uid;
  final String content;
  final Timestamp createdAt;
  PostShare({
    required this.id,
    required this.postId,
    required this.uid,
    required this.content,
    required this.createdAt,
  });

  PostShare copyWith({
    String? id,
    String? postId,
    String? uid,
    String? content,
    Timestamp? createdAt,
  }) {
    return PostShare(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'postId': postId,
      'uid': uid,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory PostShare.fromMap(Map<String, dynamic> map) {
    return PostShare(
      id: map['id'] as String,
      postId: map['postId'] as String,
      uid: map['uid'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory PostShare.fromJson(String source) =>
      PostShare.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PostShare(id: $id, postId: $postId, uid: $uid, content: $content, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant PostShare other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.postId == postId &&
        other.uid == uid &&
        other.content == content &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        postId.hashCode ^
        uid.hashCode ^
        content.hashCode ^
        createdAt.hashCode;
  }
}

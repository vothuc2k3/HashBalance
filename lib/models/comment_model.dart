// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String uid;
  final String postId;
  final String? content;
  final Timestamp createdAt;

  const Comment({
    required this.id,
    required this.uid,
    required this.postId,
    this.content,
    required this.createdAt,
  });

  Comment copyWith({
    String? id,
    String? uid,
    String? postId,
    String? content,
    Timestamp? createdAt,
  }) =>
      Comment(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        postId: postId ?? this.postId,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'uid': uid,
        'postId': postId,
        'content': content,
        'createdAt': createdAt,
      };

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      uid: map['uid'] as String,
      postId: map['postId'] as String,
      content: map['content'] != null ? map['content'] as String : '',
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, uid: $uid, postId: $postId, content: $content, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Comment other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.postId == postId &&
        other.content == content &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        postId.hashCode ^
        content.hashCode ^
        createdAt.hashCode;
  }

  String toJson() => json.encode(toMap());

  factory Comment.fromJson(String source) =>
      Comment.fromMap(json.decode(source) as Map<String, dynamic>);
}

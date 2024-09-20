// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CommentModel {
  final String id;
  final String uid;
  final String postId;
  final String? parentCommentId;
  final String? content;
  final Map<String, String>? mentionedUser;
  final Timestamp createdAt;
  CommentModel({
    required this.id,
    required this.uid,
    required this.postId,
    this.parentCommentId,
    this.content,
    this.mentionedUser,
    required this.createdAt,
  });

  CommentModel copyWith({
    String? id,
    String? uid,
    String? postId,
    String? parentCommentId,
    String? content,
    Map<String, String>? mentionedUser,
    Timestamp? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      postId: postId ?? this.postId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      mentionedUser: mentionedUser ?? this.mentionedUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'postId': postId,
      'parentCommentId': parentCommentId,
      'content': content,
      'mentionedUser': mentionedUser,
      'createdAt': createdAt,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      postId: map['postId'] as String,
      parentCommentId: map['parentCommentId'] != null
          ? map['parentCommentId'] as String
          : '',
      content: map['content'] != null ? map['content'] as String : '',
      mentionedUser: map['mentionedUser'] != null
          ? Map<String, String>.from(
              (map['mentionedUser'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value.toString(),
                ),
              ),
            )
          : {},
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory CommentModel.fromJson(String source) =>
      CommentModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CommentModel(id: $id, uid: $uid, postId: $postId, parentCommentId: $parentCommentId, content: $content, mentionedUser: $mentionedUser, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant CommentModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.postId == postId &&
        other.parentCommentId == parentCommentId &&
        other.content == content &&
        mapEquals(other.mentionedUser, mentionedUser) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        postId.hashCode ^
        parentCommentId.hashCode ^
        content.hashCode ^
        mentionedUser.hashCode ^
        createdAt.hashCode;
  }
}

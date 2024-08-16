// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String uid;
  final String postId;
  final String? parentCommentId;
  final String? content;
  final int upvoteCount;
  final int downvoteCount;
  final Timestamp createdAt;
  Comment({
    required this.id,
    required this.uid,
    required this.postId,
    this.parentCommentId,
    this.content,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.createdAt,
  });

  Comment copyWith({
    String? id,
    String? uid,
    String? postId,
    String? parentCommentId,
    String? content,
    int? upvoteCount,
    int? downvoteCount,
    Timestamp? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      postId: postId ?? this.postId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvoteCount: downvoteCount ?? this.downvoteCount,
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
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'createdAt': createdAt,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      uid: map['uid'] as String,
      postId: map['postId'] as String,
      parentCommentId:
          map['parentCommentId'] != '' ? map['parentCommentId'] as String : '',
      content: map['content'] != null ? map['content'] as String : '',
      upvoteCount: map['upvoteCount'] as int,
      downvoteCount: map['downvoteCount'] as int,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Comment.fromJson(String source) =>
      Comment.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Comment(id: $id, uid: $uid, postId: $postId, parentCommentId: $parentCommentId, content: $content, upvoteCount: $upvoteCount, downvoteCount: $downvoteCount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Comment other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.postId == postId &&
        other.parentCommentId == parentCommentId &&
        other.content == content &&
        other.upvoteCount == upvoteCount &&
        other.downvoteCount == downvoteCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        postId.hashCode ^
        parentCommentId.hashCode ^
        content.hashCode ^
        upvoteCount.hashCode ^
        downvoteCount.hashCode ^
        createdAt.hashCode;
  }
}

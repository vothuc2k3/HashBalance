import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Comment {
  final String id;
  final String uid;
  final String postId;
  final String? content;
  final Timestamp createdAt;
  final List<String> upvotes;
  final List<String> downvotes;
  final int upvoteCount;
  Comment({
    required this.id,
    required this.uid,
    required this.postId,
    this.content,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.upvoteCount,
  });

  Comment copyWith({
    String? id,
    String? uid,
    String? postId,
    String? content,
    Timestamp? createdAt,
    List<String>? upvotes,
    List<String>? downvotes,
    int? upvoteCount,
  }) {
    return Comment(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      upvoteCount: upvoteCount ?? this.upvoteCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'postId': postId,
      'content': content,
      'createdAt': createdAt,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvoteCount': upvoteCount,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      uid: map['uid'] as String,
      postId: map['postId'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      createdAt: map['createdAt'] as Timestamp,
      upvotes: List<String>.from((map['upvotes'] as List<String>)),
      downvotes: List<String>.from((map['downvotes'] as List<String>)),
      upvoteCount: map['upvoteCount'] as int,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, uid: $uid, postId: $postId, content: $content, createdAt: $createdAt, upvotes: $upvotes, downvotes: $downvotes, upvoteCount: $upvoteCount)';
  }

  @override
  bool operator ==(covariant Comment other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.postId == postId &&
        other.content == content &&
        other.createdAt == createdAt &&
        listEquals(other.upvotes, upvotes) &&
        listEquals(other.downvotes, downvotes) &&
        other.upvoteCount == upvoteCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        postId.hashCode ^
        content.hashCode ^
        createdAt.hashCode ^
        upvotes.hashCode ^
        downvotes.hashCode ^
        upvoteCount.hashCode;
  }
}

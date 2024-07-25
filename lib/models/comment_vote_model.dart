// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class CommentVote {
  final String id;
  final String commentId;
  final String uid;
  final bool isUpvoted;
  final Timestamp createdAt;
  CommentVote({
    required this.id,
    required this.commentId,
    required this.uid,
    required this.isUpvoted,
    required this.createdAt,
  });

  CommentVote copyWith({
    String? id,
    String? commentId,
    String? uid,
    bool? isUpvoted,
    Timestamp? createdAt,
  }) {
    return CommentVote(
      id: id ?? this.id,
      commentId: commentId ?? this.commentId,
      uid: uid ?? this.uid,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'commentId': commentId,
      'uid': uid,
      'isUpvoted': isUpvoted,
      'createdAt': createdAt,
    };
  }

  factory CommentVote.fromMap(Map<String, dynamic> map) {
    return CommentVote(
      id: map['id'] as String,
      commentId: map['commentId'] as String,
      uid: map['uid'] as String,
      isUpvoted: map['isUpvoted'] as bool,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory CommentVote.fromJson(String source) =>
      CommentVote.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CommentVote(id: $id, commentId: $commentId, uid: $uid, isUpvoted: $isUpvoted, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant CommentVote other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.commentId == commentId &&
        other.uid == uid &&
        other.isUpvoted == isUpvoted &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        commentId.hashCode ^
        uid.hashCode ^
        isUpvoted.hashCode ^
        createdAt.hashCode;
  }
}

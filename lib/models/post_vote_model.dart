// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class PostVote {
  final String id;
  final String postId;
  final String uid;
  final bool isUpvoted;
  final Timestamp createdAt;
  PostVote({
    required this.id,
    required this.postId,
    required this.uid,
    required this.isUpvoted,
    required this.createdAt,
  });

  PostVote copyWith({
    String? id,
    String? postId,
    String? uid,
    bool? isUpvoted,
    Timestamp? createdAt,
  }) {
    return PostVote(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      uid: uid ?? this.uid,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'postId': postId,
      'uid': uid,
      'isUpvoted': isUpvoted,
      'createdAt': createdAt,
    };
  }

  factory PostVote.fromMap(Map<String, dynamic> map) {
    return PostVote(
      id: map['id'] as String,
      postId: map['postId'] as String,
      uid: map['uid'] as String,
      isUpvoted: map['isUpvoted'] as bool,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory PostVote.fromJson(String source) =>
      PostVote.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PostVote(id: $id, postId: $postId, uid: $uid, isUpvoted: $isUpvoted, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant PostVote other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.postId == postId &&
      other.uid == uid &&
      other.isUpvoted == isUpvoted &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      postId.hashCode ^
      uid.hashCode ^
      isUpvoted.hashCode ^
      createdAt.hashCode;
  }
}

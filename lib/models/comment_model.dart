import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Comment {
  final String uid;
  final String postId;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  final List<String> upvotes;
  final int upvoteCount;
  final List<String> downvotes;
  final List<String> replies;
  Comment({
    required this.uid,
    required this.postId,
    this.content,
    this.image,
    this.video,
    required this.createdAt,
    required this.upvotes,
    required this.upvoteCount,
    required this.downvotes,
    required this.replies,
  });

  Comment copyWith({
    String? uid,
    String? postId,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
    List<String>? upvotes,
    int? upvoteCount,
    List<String>? downvotes,
    List<String>? replies,
  }) {
    return Comment(
      uid: uid ?? this.uid,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvotes: downvotes ?? this.downvotes,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'postId': postId,
      'content': content,
      'image': image,
      'video': video,
      'createdAt': createdAt,
      'upvotes': upvotes,
      'upvoteCount': upvoteCount,
      'downvotes': downvotes,
      'replies': replies,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      uid: map['uid'] as String,
      postId: map['postId'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      image: map['image'] != null ? map['image'] as String : null,
      video: map['video'] != null ? map['video'] as String : null,
      createdAt: map['createdAt'] as Timestamp,
      upvotes: List<String>.from((map['upvotes'] as List<String>)),
      upvoteCount: map['upvoteCount'] as int,
      downvotes: List<String>.from((map['downvotes'] as List<String>)),
      replies: List<String>.from((map['replies'] as List<String>)),
    );
  }

  @override
  String toString() {
    return 'Comment(uid: $uid, postId: $postId, content: $content, image: $image, video: $video, createdAt: $createdAt, upvotes: $upvotes, upvoteCount: $upvoteCount, downvotes: $downvotes, replies: $replies)';
  }

  @override
  bool operator ==(covariant Comment other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.postId == postId &&
        other.content == content &&
        other.image == image &&
        other.video == video &&
        other.createdAt == createdAt &&
        listEquals(other.upvotes, upvotes) &&
        other.upvoteCount == upvoteCount &&
        listEquals(other.downvotes, downvotes) &&
        listEquals(other.replies, replies);
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        postId.hashCode ^
        content.hashCode ^
        image.hashCode ^
        video.hashCode ^
        createdAt.hashCode ^
        upvotes.hashCode ^
        upvoteCount.hashCode ^
        downvotes.hashCode ^
        replies.hashCode;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String userId;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  final int upvotes;
  final int downvotes;
  final List<String> comments;
  Post({
    required this.id,
    required this.userId,
    this.content,
    this.image,
    this.video,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.comments,
  });

  Post copyWith({
    String? id,
    String? userId,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
    int? upvotes,
    int? downvotes,
    List<String>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'content': content,
      'image': image,
      'video': video,
      'createdAt': createdAt,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'comments': comments,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      userId: map['userId'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      image: map['image'] != null ? map['image'] as String : null,
      video: map['video'] != null ? map['video'] as String : null,
      createdAt: map['createdAt'] as Timestamp,
      upvotes: map['upvotes'] as int,
      downvotes: map['downvotes'] as int,
      comments: List<String>.from(
        (map['comments'] as List<String>),
      ),
    );
  }
  @override
  String toString() {
    return 'Post(id: $id, userId: $userId, content: $content, image: $image, video: $video, createdAt: $createdAt, upvotes: $upvotes, downvotes: $downvotes, comments: $comments)';
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.userId == userId &&
        other.content == content &&
        other.image == image &&
        other.video == video &&
        other.createdAt == createdAt &&
        other.upvotes == upvotes &&
        other.downvotes == downvotes &&
        listEquals(other.comments, comments);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        content.hashCode ^
        image.hashCode ^
        video.hashCode ^
        createdAt.hashCode ^
        upvotes.hashCode ^
        downvotes.hashCode ^
        comments.hashCode;
  }
}

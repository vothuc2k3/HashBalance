import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Post {
  final String communityName;
  final String uid;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  final int upvotes;
  final int downvotes;
  final List<String> comments;
  Post({
    required this.communityName,
    required this.uid,
    this.content,
    this.image,
    this.video,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.comments,
  });

  Post copyWith({
    String? communityName,
    String? uid,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
    int? upvotes,
    int? downvotes,
    List<String>? comments,
  }) {
    return Post(
      communityName: communityName ?? this.communityName,
      uid: uid ?? this.uid,
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
      'communityName': communityName,
      'uid': uid,
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
      communityName: map['communityName'] as String,
      uid: map['uid'] as String,
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
    return 'Post(communityName: $communityName, uid: $uid, content: $content, image: $image, video: $video, createdAt: $createdAt, upvotes: $upvotes, downvotes: $downvotes, comments: $comments)';
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;

    return other.communityName == communityName &&
        other.uid == uid &&
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
    return communityName.hashCode ^
        uid.hashCode ^
        content.hashCode ^
        image.hashCode ^
        video.hashCode ^
        createdAt.hashCode ^
        upvotes.hashCode ^
        downvotes.hashCode ^
        comments.hashCode;
  }
}
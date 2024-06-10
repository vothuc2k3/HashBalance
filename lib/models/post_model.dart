import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String communityName;
  final String uid;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  final List<String> upvotes;
  final List<String> downvotes;
  final int upvoteCount;
  Post({
    required this.id,
    required this.communityName,
    required this.uid,
    this.content,
    this.image,
    this.video,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.upvoteCount,
  });

  Post copyWith({
    String? id,
    String? communityName,
    String? uid,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
    List<String>? upvotes,
    List<String>? downvotes,
    int? upvoteCount,
  }) {
    return Post(
      id: id ?? this.id,
      communityName: communityName ?? this.communityName,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      upvoteCount: upvoteCount ?? this.upvoteCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'communityName': communityName,
      'uid': uid,
      'content': content,
      'image': image,
      'video': video,
      'createdAt': createdAt,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvoteCount': upvoteCount,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      communityName: map['communityName'] as String,
      uid: map['uid'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      image: map['image'] != null ? map['image'] as String : null,
      video: map['video'] != null ? map['video'] as String : null,
      createdAt: map['createdAt'] as Timestamp,
      upvotes: List<String>.from((map['upvotes'] as List<String>)),
      downvotes: List<String>.from((map['downvotes'] as List<String>)),
      upvoteCount: map['upvoteCount'] as int,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, communityName: $communityName, uid: $uid, content: $content, image: $image, video: $video, createdAt: $createdAt, upvotes: $upvotes, downvotes: $downvotes, upvoteCount: $upvoteCount)';
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.communityName == communityName &&
        other.uid == uid &&
        other.content == content &&
        other.image == image &&
        other.video == video &&
        other.createdAt == createdAt &&
        listEquals(other.upvotes, upvotes) &&
        listEquals(other.downvotes, downvotes) &&
        other.upvoteCount == upvoteCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        communityName.hashCode ^
        uid.hashCode ^
        content.hashCode ^
        image.hashCode ^
        video.hashCode ^
        createdAt.hashCode ^
        upvotes.hashCode ^
        downvotes.hashCode ^
        upvoteCount.hashCode;
  }
}

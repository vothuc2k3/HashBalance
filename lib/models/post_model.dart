// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String communityId;
  final String uid;
  final String content;
  final String? image;
  final String? video;
  final int upvoteCount;
  final int downvoteCount;
  final int commentCount;
  final int shareCount;
  final String status;
  final bool isEdited;
  final Timestamp createdAt;
  Post({
    required this.id,
    required this.communityId,
    required this.uid,
    required this.content,
    this.image,
    this.video,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.commentCount,
    required this.shareCount,
    required this.status,
    required this.isEdited,
    required this.createdAt,
  });

  Post copyWith({
    String? id,
    String? communityId,
    String? uid,
    String? content,
    String? image,
    String? video,
    int? upvoteCount,
    int? downvoteCount,
    int? commentCount,
    int? shareCount,
    String? status,
    bool? isEdited,
    Timestamp? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      downvoteCount: downvoteCount ?? this.downvoteCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'communityId': communityId,
      'uid': uid,
      'content': content,
      'image': image,
      'video': video,
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'status': status,
      'isEdited': isEdited,
      'createdAt': createdAt,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      communityId: map['communityId'] as String,
      uid: map['uid'] as String,
      content: map['content'] as String,
      image: map['image'] != null ? map['image'] as String : '',
      video: map['video'] != null ? map['video'] as String : '',
      upvoteCount: map['upvoteCount'] as int,
      downvoteCount: map['downvoteCount'] as int,
      commentCount: map['commentCount'] as int,
      shareCount: map['shareCount'] as int,
      status: map['status'] as String,
      isEdited: map['isEdited'] as bool,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) => Post.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Post(id: $id, communityId: $communityId, uid: $uid, content: $content, image: $image, video: $video, upvoteCount: $upvoteCount, downvoteCount: $downvoteCount, commentCount: $commentCount, shareCount: $shareCount, status: $status, isEdited: $isEdited, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.communityId == communityId &&
      other.uid == uid &&
      other.content == content &&
      other.image == image &&
      other.video == video &&
      other.upvoteCount == upvoteCount &&
      other.downvoteCount == downvoteCount &&
      other.commentCount == commentCount &&
      other.shareCount == shareCount &&
      other.status == status &&
      other.isEdited == isEdited &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      communityId.hashCode ^
      uid.hashCode ^
      content.hashCode ^
      image.hashCode ^
      video.hashCode ^
      upvoteCount.hashCode ^
      downvoteCount.hashCode ^
      commentCount.hashCode ^
      shareCount.hashCode ^
      status.hashCode ^
      isEdited.hashCode ^
      createdAt.hashCode;
  }
}

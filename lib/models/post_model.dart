import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String communityId;
  final String uid;
  final bool isPoll;
  final String content;
  final List<String>? image;
  final String? video;
  final String status;
  final bool isPinned;
  final bool isEdited;
  final Timestamp createdAt;
  Post({
    required this.id,
    required this.communityId,
    required this.uid,
    required this.isPoll,
    required this.content,
    this.image,
    this.video,
    required this.status,
    required this.isPinned,
    required this.isEdited,
    required this.createdAt,
  });

  Post copyWith({
    String? id,
    String? communityId,
    String? uid,
    bool? isPoll,
    String? content,
    List<String>? image,
    String? video,
    String? status,
    bool? isPinned,
    bool? isEdited,
    Timestamp? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      uid: uid ?? this.uid,
      isPoll: isPoll ?? this.isPoll,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'communityId': communityId,
      'uid': uid,
      'isPoll': isPoll,
      'content': content,
      'image': image,
      'video': video,
      'status': status,
      'isPinned': isPinned,
      'isEdited': isEdited,
      'createdAt': createdAt,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      communityId: map['communityId'] as String,
      uid: map['uid'] as String,
      isPoll: map['isPoll'] as bool,
      content: map['content'] as String,
      image: map['image'] != null
          ? List<String>.from(
              (map['image'] as List<dynamic>),
            )
          : null,
      video: map['video'] != null ? map['video'] as String : null,
      status: map['status'] as String,
      isPinned: map['isPinned'] as bool,
      isEdited: map['isEdited'] as bool,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) =>
      Post.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Post(id: $id, communityId: $communityId, uid: $uid, isPoll: $isPoll, content: $content, image: $image, video: $video, status: $status, isPinned: $isPinned, isEdited: $isEdited, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.communityId == communityId &&
        other.uid == uid &&
        other.isPoll == isPoll &&
        other.content == content &&
        listEquals(other.image, image) &&
        other.video == video &&
        other.status == status &&
        other.isPinned == isPinned &&
        other.isEdited == isEdited &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        communityId.hashCode ^
        uid.hashCode ^
        isPoll.hashCode ^
        content.hashCode ^
        image.hashCode ^
        video.hashCode ^
        status.hashCode ^
        isPinned.hashCode ^
        isEdited.hashCode ^
        createdAt.hashCode;
  }
}

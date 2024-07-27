// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String communityId;
  final String uid;
  final String? content;
  final String? image;
  final String? video;
  final String status;
  final Timestamp createdAt;
  Post({
    required this.id,
    required this.communityId,
    required this.uid,
    this.content,
    this.image,
    this.video,
    required this.status,
    required this.createdAt,
  });

  Post copyWith({
    String? id,
    String? communityId,
    String? uid,
    String? content,
    String? image,
    String? video,
    String? status,
    Timestamp? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      status: status ?? this.status,
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
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      communityId: map['communityId'] as String,
      uid: map['uid'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      image: map['image'] != null ? map['image'] as String : null,
      video: map['video'] != null ? map['video'] as String : null,
      status: map['status'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, communityId: $communityId, uid: $uid, content: $content, image: $image, video: $video, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.communityId == communityId &&
        other.uid == uid &&
        other.content == content &&
        other.image == image &&
        other.video == video &&
        other.status == status &&
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
        status.hashCode ^
        createdAt.hashCode;
  }

  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) =>
      Post.fromMap(json.decode(source) as Map<String, dynamic>);
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String communityName;
  final String uid;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  Post({
    required this.id,
    required this.communityName,
    required this.uid,
    this.content,
    this.image,
    this.video,
    required this.createdAt,
  });

  Post copyWith({
    String? id,
    String? communityName,
    String? uid,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      communityName: communityName ?? this.communityName,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      createdAt: createdAt ?? this.createdAt,
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
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, communityName: $communityName, uid: $uid, content: $content, image: $image, video: $video, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Post other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.communityName == communityName &&
      other.uid == uid &&
      other.content == content &&
      other.image == image &&
      other.video == video &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      communityName.hashCode ^
      uid.hashCode ^
      content.hashCode ^
      image.hashCode ^
      video.hashCode ^
      createdAt.hashCode;
  }

  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) => Post.fromMap(json.decode(source) as Map<String, dynamic>);
}

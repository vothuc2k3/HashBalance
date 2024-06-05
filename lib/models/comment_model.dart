import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String uid;
  final String postId;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  Comment({
    required this.uid,
    required this.postId,
    this.content,
    this.image,
    this.video,
    required this.createdAt,
  });

  Comment copyWith({
    String? uid,
    String? postId,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
  }) {
    return Comment(
      uid: uid ?? this.uid,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      createdAt: createdAt ?? this.createdAt,
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
    );
  }

  @override
  String toString() {
    return 'Comment(uid: $uid, postId: $postId, content: $content, image: $image, video: $video, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Comment other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.postId == postId &&
        other.content == content &&
        other.image == image &&
        other.video == video &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        postId.hashCode ^
        content.hashCode ^
        image.hashCode ^
        video.hashCode ^
        createdAt.hashCode;
  }
}

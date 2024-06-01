import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String uid;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  final int upvotes;
  final int downvotes;
  final bool isEdited;
  Comment({
    required this.id,
    required this.postId,
    required this.uid,
    this.content,
    this.image,
    this.video,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.isEdited,
  });

  Comment copyWith({
    String? id,
    String? postId,
    String? uid,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
    int? upvotes,
    int? downvotes,
    bool? isEdited,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      image: image ?? this.image,
      video: video ?? this.video,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'postId': postId,
      'uid': uid,
      'content': content,
      'image': image,
      'video': video,
      'createdAt': createdAt,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isEdited': isEdited,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      postId: map['postId'] as String,
      uid: map['uid'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      image: map['image'] != null ? map['image'] as String : null,
      video: map['video'] != null ? map['video'] as String : null,
      createdAt: map['createdAt'] as Timestamp,
      upvotes: map['upvotes'] as int,
      downvotes: map['downvotes'] as int,
      isEdited: map['isEdited'] as bool,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, postId: $postId, uid: $uid, content: $content, image: $image, video: $video, createdAt: $createdAt, upvotes: $upvotes, downvotes: $downvotes, isEdited: $isEdited)';
  }

  @override
  bool operator ==(covariant Comment other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.postId == postId &&
        other.uid == uid &&
        other.content == content &&
        other.image == image &&
        other.video == video &&
        other.createdAt == createdAt &&
        other.upvotes == upvotes &&
        other.downvotes == downvotes &&
        other.isEdited == isEdited;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        postId.hashCode ^
        uid.hashCode ^
        content.hashCode ^
        image.hashCode ^
        video.hashCode ^
        createdAt.hashCode ^
        upvotes.hashCode ^
        downvotes.hashCode ^
        isEdited.hashCode;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String communityName;
  final String uid;
  final String? content;
  final String? image;
  final String? video;
  final Timestamp createdAt;
  final int upvotes;
  final int downvotes;
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
  });

  Post copyWith({
    String? id,
    String? communityName,
    String? uid,
    String? content,
    String? image,
    String? video,
    Timestamp? createdAt,
    int? upvotes,
    int? downvotes,
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
      upvotes: map['upvotes'] as int,
      downvotes: map['downvotes'] as int,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, communityName: $communityName, uid: $uid, content: $content, image: $image, video: $video, createdAt: $createdAt, upvotes: $upvotes, downvotes: $downvotes)';
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
        other.upvotes == upvotes &&
        other.downvotes == downvotes;
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
        downvotes.hashCode;
  }
}

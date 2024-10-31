import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class LivestreamComment {
  final String id;
  final String streamId;
  final String content;
  final String uid;
  final Timestamp createdAt;
  LivestreamComment({
    required this.id,
    required this.streamId,
    required this.content,
    required this.uid,
    required this.createdAt,
  });

  LivestreamComment copyWith({
    String? id,
    String? streamId,
    String? content,
    String? uid,
    Timestamp? createdAt,
  }) {
    return LivestreamComment(
      id: id ?? this.id,
      streamId: streamId ?? this.streamId,
      content: content ?? this.content,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'streamId': streamId,
      'content': content,
      'uid': uid,
      'createdAt': createdAt,
    };
  }

  factory LivestreamComment.fromMap(Map<String, dynamic> map) {
    return LivestreamComment(
      id: map['id'] as String,
      streamId: map['streamId'] as String,
      content: map['content'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory LivestreamComment.fromJson(String source) => LivestreamComment.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LivestreamComment(id: $id, streamId: $streamId, content: $content, uid: $uid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant LivestreamComment other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.streamId == streamId &&
      other.content == content &&
      other.uid == uid &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      streamId.hashCode ^
      content.hashCode ^
      uid.hashCode ^
      createdAt.hashCode;
  }
}

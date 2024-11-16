import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Livestream {
  final String id;
  final String content;
  final String uid;
  final String communityId;
  final String status;
  final String? agoraToken;
  final List<String>? viewers;
  final Timestamp createdAt;
  Livestream({
    required this.id,
    required this.content,
    required this.uid,
    required this.communityId,
    required this.status,
    this.agoraToken,
    this.viewers,
    required this.createdAt,
  });

  Livestream copyWith({
    String? id,
    String? content,
    String? uid,
    String? communityId,
    String? status,
    String? agoraToken,
    List<String>? viewers,
    Timestamp? createdAt,
  }) {
    return Livestream(
      id: id ?? this.id,
      content: content ?? this.content,
      uid: uid ?? this.uid,
      communityId: communityId ?? this.communityId,
      status: status ?? this.status,
      agoraToken: agoraToken ?? this.agoraToken,
      viewers: viewers ?? this.viewers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'content': content,
      'uid': uid,
      'communityId': communityId,
      'status': status,
      'agoraToken': agoraToken,
      'viewers': viewers,
      'createdAt': createdAt,
    };
  }

  factory Livestream.fromMap(Map<String, dynamic> map) {
    return Livestream(
      id: map['id'] as String,
      content: map['content'] as String,
      uid: map['uid'] as String,
      communityId: map['communityId'] as String,
      status: map['status'] as String,
      agoraToken:
          map['agoraToken'] != null ? map['agoraToken'] as String : null,
      viewers: map['viewers'] != null
          ? List<String>.from((map['viewers'] as List<dynamic>))
          : null,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Livestream.fromJson(String source) =>
      Livestream.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Livestream(id: $id, content: $content, uid: $uid, communityId: $communityId, status: $status, agoraToken: $agoraToken, viewers: $viewers, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Livestream other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.content == content &&
        other.uid == uid &&
        other.communityId == communityId &&
        other.status == status &&
        other.agoraToken == agoraToken &&
        listEquals(other.viewers, viewers) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        uid.hashCode ^
        communityId.hashCode ^
        status.hashCode ^
        agoraToken.hashCode ^
        viewers.hashCode ^
        createdAt.hashCode;
  }
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String type;
  final String reporterUid;
  final String? postId;
  final String? communityId;
  final String? commentId;
  final String? userId;
  final String reportMessage;
  final Timestamp createdAt;
  Report({
    required this.id,
    required this.type,
    required this.reporterUid,
    this.postId,
    this.communityId,
    this.commentId,
    this.userId,
    required this.reportMessage,
    required this.createdAt,
  });

  Report copyWith({
    String? id,
    String? type,
    String? reporterUid,
    String? postId,
    String? communityId,
    String? commentId,
    String? userId,
    String? reportMessage,
    Timestamp? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      type: type ?? this.type,
      reporterUid: reporterUid ?? this.reporterUid,
      postId: postId ?? this.postId,
      communityId: communityId ?? this.communityId,
      commentId: commentId ?? this.commentId,
      userId: userId ?? this.userId,
      reportMessage: reportMessage ?? this.reportMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'reporterUid': reporterUid,
      'postId': postId,
      'communityId': communityId,
      'commentId': commentId,
      'userId': userId,
      'reportMessage': reportMessage,
      'createdAt': createdAt,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      type: map['type'] as String,
      reporterUid: map['reporterUid'] as String,
      postId: map['postId'] != null ? map['postId'] as String : null,
      communityId:
          map['communityId'] != null ? map['communityId'] as String : null,
      commentId: map['commentId'] != null ? map['commentId'] as String : null,
      userId: map['userId'] != null ? map['userId'] as String : null,
      reportMessage: map['reportMessage'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Report.fromJson(String source) =>
      Report.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Report(id: $id, type: $type, reporterUid: $reporterUid, postId: $postId, communityId: $communityId, commentId: $commentId, userId: $userId, reportMessage: $reportMessage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Report other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.type == type &&
        other.reporterUid == reporterUid &&
        other.postId == postId &&
        other.communityId == communityId &&
        other.commentId == commentId &&
        other.userId == userId &&
        other.reportMessage == reportMessage &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        reporterUid.hashCode ^
        postId.hashCode ^
        communityId.hashCode ^
        commentId.hashCode ^
        userId.hashCode ^
        reportMessage.hashCode ^
        createdAt.hashCode;
  }
}

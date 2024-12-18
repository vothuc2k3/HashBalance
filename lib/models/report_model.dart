import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String type;
  final String reporterUid;
  final String? communityId;
  final String? reportedPostId;
  final String? reportedCommentId;
  final String? reportedUid;
  final String? reportedCommunityId;
  final bool isResolved;
  final String message;
  final Timestamp createdAt;
  Report({
    required this.id,
    required this.type,
    required this.reporterUid,
    this.communityId,
    this.reportedPostId,
    this.reportedCommentId,
    this.reportedUid,
    this.reportedCommunityId,
    required this.isResolved,
    required this.message,
    required this.createdAt,
  });

  Report copyWith({
    String? id,
    String? type,
    String? reporterUid,
    String? communityId,
    String? reportedPostId,
    String? reportedCommentId,
    String? reportedUid,
    String? reportedCommunityId,
    bool? isResolved,
    String? message,
    Timestamp? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      type: type ?? this.type,
      reporterUid: reporterUid ?? this.reporterUid,
      communityId: communityId ?? this.communityId,
      reportedPostId: reportedPostId ?? this.reportedPostId,
      reportedCommentId: reportedCommentId ?? this.reportedCommentId,
      reportedUid: reportedUid ?? this.reportedUid,
      reportedCommunityId: reportedCommunityId ?? this.reportedCommunityId,
      isResolved: isResolved ?? this.isResolved,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'reporterUid': reporterUid,
      'communityId': communityId,
      'reportedPostId': reportedPostId,
      'reportedCommentId': reportedCommentId,
      'reportedUid': reportedUid,
      'reportedCommunityId': reportedCommunityId,
      'isResolved': isResolved,
      'message': message,
      'createdAt': createdAt,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      type: map['type'] as String,
      reporterUid: map['reporterUid'] as String,
      communityId:
          map['communityId'] != null ? map['communityId'] as String : null,
      reportedPostId: map['reportedPostId'] != null
          ? map['reportedPostId'] as String
          : null,
      reportedCommentId: map['reportedCommentId'] != null
          ? map['reportedCommentId'] as String
          : null,
      reportedUid:
          map['reportedUid'] != null ? map['reportedUid'] as String : null,
      reportedCommunityId: map['reportedCommunityId'] != null
          ? map['reportedCommunityId'] as String
          : null,
      isResolved: map['isResolved'] as bool,
      message: map['message'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Report.fromJson(String source) =>
      Report.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Report(id: $id, type: $type, reporterUid: $reporterUid, communityId: $communityId, reportedPostId: $reportedPostId, reportedCommentId: $reportedCommentId, reportedUid: $reportedUid, reportedCommunityId: $reportedCommunityId, isResolved: $isResolved, message: $message, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Report other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.type == type &&
        other.reporterUid == reporterUid &&
        other.communityId == communityId &&
        other.reportedPostId == reportedPostId &&
        other.reportedCommentId == reportedCommentId &&
        other.reportedUid == reportedUid &&
        other.reportedCommunityId == reportedCommunityId &&
        other.isResolved == isResolved &&
        other.message == message &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        reporterUid.hashCode ^
        communityId.hashCode ^
        reportedPostId.hashCode ^
        reportedCommentId.hashCode ^
        reportedUid.hashCode ^
        reportedCommunityId.hashCode ^
        isResolved.hashCode ^
        message.hashCode ^
        createdAt.hashCode;
  }
}

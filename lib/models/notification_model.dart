import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;

  final String? targetUid;
  final String senderUid;
  final String? postId;
  final String? communityId;
  final String? commentId;
  final String? conversationId;
  final Timestamp createdAt;
  final bool isRead;
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetUid,
    required this.senderUid,
    this.postId,
    this.communityId,
    this.commentId,
    this.conversationId,
    required this.createdAt,
    required this.isRead,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? targetUid,
    String? senderUid,
    String? postId,
    String? communityId,
    String? commentId,
    String? conversationId,
    Timestamp? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetUid: targetUid ?? this.targetUid,
      senderUid: senderUid ?? this.senderUid,
      postId: postId ?? this.postId,
      communityId: communityId ?? this.communityId,
      commentId: commentId ?? this.commentId,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'targetUid': targetUid,
      'senderUid': senderUid,
      'postId': postId,
      'communityId': communityId,
      'commentId': commentId,
      'conversationId': conversationId,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      targetUid: map['targetUid'] != null ? map['targetUid'] as String : '',
      senderUid: map['senderUid'] as String,
      postId: map['postId'] != null ? map['postId'] as String : '',
      communityId: map['communityId'] != null ? map['communityId'] as String : '',
      commentId: map['commentId'] != null ? map['commentId'] as String : '',
      conversationId: map['conversationId'] != null ? map['conversationId'] as String : '',
      createdAt: map['createdAt'] as Timestamp,
      isRead: map['isRead'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, type: $type, targetUid: $targetUid, senderUid: $senderUid, postId: $postId, communityId: $communityId, commentId: $commentId, conversationId: $conversationId, createdAt: $createdAt, isRead: $isRead)';
  }

  @override
  bool operator ==(covariant NotificationModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.targetUid == targetUid &&
        other.senderUid == senderUid &&
        other.postId == postId &&
        other.communityId == communityId &&
        other.commentId == commentId &&
        other.conversationId == conversationId &&
        other.createdAt == createdAt &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        message.hashCode ^
        type.hashCode ^
        targetUid.hashCode ^
        senderUid.hashCode ^
        postId.hashCode ^
        communityId.hashCode ^
        commentId.hashCode ^
        conversationId.hashCode ^
        createdAt.hashCode ^
        isRead.hashCode;
  }
}

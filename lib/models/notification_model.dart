// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? targetUid;
  final String? postId;
  final Timestamp createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetUid,
    this.postId,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? targetUid,
    String? postId,
    Timestamp? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetUid: targetUid ?? this.targetUid,
      postId: postId ?? this.postId,
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
      'postId': postId,
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
      targetUid: map['targetUid'] != null ? map['targetUid'] as String : null,
      postId: map['postId'] != null ? map['postId'] as String : null,
      createdAt: map['createdAt'] as Timestamp,
      isRead: map['isRead'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, type: $type, targetUid: $targetUid, postId: $postId, createdAt: $createdAt, isRead: $isRead)';
  }

  @override
  bool operator ==(covariant NotificationModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.title == title &&
      other.message == message &&
      other.type == type &&
      other.targetUid == targetUid &&
      other.postId == postId &&
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
      postId.hashCode ^
      createdAt.hashCode ^
      isRead.hashCode;
  }
}

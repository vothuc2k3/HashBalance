import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String uid;
  final String activityType;
  final String title;
  final String message;
  final Timestamp createdAt;
  ActivityLogModel({
    required this.id,
    required this.uid,
    required this.activityType,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  ActivityLogModel copyWith({
    String? id,
    String? uid,
    String? activityType,
    String? title,
    String? message,
    Timestamp? createdAt,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'activityType': activityType,
      'title': title,
      'message': message,
      'createdAt': createdAt,
    };
  }

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      activityType: map['activityType'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory ActivityLogModel.fromJson(String source) =>
      ActivityLogModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ActivityLogModel(id: $id, uid: $uid, activityType: $activityType, title: $title, message: $message, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant ActivityLogModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.activityType == activityType &&
        other.title == title &&
        other.message == message &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        activityType.hashCode ^
        title.hashCode ^
        message.hashCode ^
        createdAt.hashCode;
  }
}

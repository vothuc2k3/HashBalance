import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String uid;
  final String type;
  final String status;
  final String title;
  final String message;
  final Timestamp createdAt;
  final bool read;
  NotificationModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
  });

  NotificationModel copyWith({
    String? id,
    String? uid,
    String? type,
    String? status,
    String? title,
    String? message,
    Timestamp? createdAt,
    bool? read,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'type': type,
      'status': status,
      'title': title,
      'message': message,
      'createdAt': createdAt,
      'read': read,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: map['createdAt'] as Timestamp,
      read: map['read'] as bool,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, uid: $uid, type: $type, status: $status, title: $title, message: $message, createdAt: $createdAt, read: $read)';
  }

  @override
  bool operator ==(covariant NotificationModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.type == type &&
        other.status == status &&
        other.title == title &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.read == read;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        uid.hashCode ^
        type.hashCode ^
        status.hashCode ^
        title.hashCode ^
        message.hashCode ^
        createdAt.hashCode ^
        read.hashCode;
  }
}

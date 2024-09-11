import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Call {
  final String id;
  final String callerUid;
  final String receiverUid;
  final String status;
  final Timestamp createdAt;
  Call({
    required this.id,
    required this.callerUid,
    required this.receiverUid,
    required this.status,
    required this.createdAt,
  });

  Call copyWith({
    String? id,
    String? callerUid,
    String? receiverUid,
    String? status,
    Timestamp? createdAt,
  }) {
    return Call(
      id: id ?? this.id,
      callerUid: callerUid ?? this.callerUid,
      receiverUid: receiverUid ?? this.receiverUid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'callerUid': callerUid,
      'receiverUid': receiverUid,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Call.fromMap(Map<String, dynamic> map) {
    return Call(
      id: map['id'] as String,
      callerUid: map['callerUid'] as String,
      receiverUid: map['receiverUid'] as String,
      status: map['status'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Call.fromJson(String source) =>
      Call.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Call(id: $id, callerUid: $callerUid, receiverUid: $receiverUid, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Call other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.callerUid == callerUid &&
        other.receiverUid == receiverUid &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        callerUid.hashCode ^
        receiverUid.hashCode ^
        status.hashCode ^
        createdAt.hashCode;
  }
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class SuspendUserModel {
  final String id;
  final String uid;
  final String communityId;
  final String reason;
  final bool isPermanent;
  final int? days;
  final Timestamp suspendedAt;
  final Timestamp? expiresAt;
  final Timestamp createdAt;
  SuspendUserModel({
    required this.id,
    required this.uid,
    required this.communityId,
    required this.reason,
    required this.isPermanent,
    this.days,
    required this.suspendedAt,
    this.expiresAt,
    required this.createdAt,
  });

  SuspendUserModel copyWith({
    String? id,
    String? uid,
    String? communityId,
    String? reason,
    bool? isPermanent,
    int? days,
    Timestamp? suspendedAt,
    Timestamp? expiresAt,
    Timestamp? createdAt,
  }) {
    return SuspendUserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      communityId: communityId ?? this.communityId,
      reason: reason ?? this.reason,
      isPermanent: isPermanent ?? this.isPermanent,
      days: days ?? this.days,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'communityId': communityId,
      'reason': reason,
      'isPermanent': isPermanent,
      'days': days,
      'suspendedAt': suspendedAt,
      'expiresAt': expiresAt,
      'createdAt': createdAt,
    };
  }

  factory SuspendUserModel.fromMap(Map<String, dynamic> map) {
    return SuspendUserModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      communityId: map['communityId'] as String,
      reason: map['reason'] as String,
      isPermanent: map['isPermanent'] as bool,
      days: map['days'] != null ? map['days'] as int : null,
      suspendedAt: map['suspendedAt'] as Timestamp,
      expiresAt: map['expiresAt'] != null ? map['expiresAt'] as Timestamp : null,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory SuspendUserModel.fromJson(String source) =>
      SuspendUserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SuspendUserModel(id: $id, uid: $uid, communityId: $communityId, reason: $reason, isPermanent: $isPermanent, days: $days, suspendedAt: $suspendedAt, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant SuspendUserModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.uid == uid &&
      other.communityId == communityId &&
      other.reason == reason &&
      other.isPermanent == isPermanent &&
      other.days == days &&
      other.suspendedAt == suspendedAt &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      uid.hashCode ^
      communityId.hashCode ^
      reason.hashCode ^
      isPermanent.hashCode ^
      days.hashCode ^
      suspendedAt.hashCode ^
      expiresAt.hashCode ^
      createdAt.hashCode;
  }
}

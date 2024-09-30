import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class SuspendUserModel {
  final String id;
  final String uid;
  final String communityId;
  final String reason;
  final bool
      isPermanent; // true if the suspension is permanent, false if it's temporary
  final int? days;
  final Timestamp suspendedAt;
  final Timestamp? expiresAt;
  SuspendUserModel({
    required this.id,
    required this.uid,
    required this.communityId,
    required this.reason,
    required this.isPermanent,
    required this.suspendedAt,
    this.expiresAt,
    this.days,
  });

  SuspendUserModel copyWith({
    String? id,
    String? uid,
    String? communityId,
    String? reason,
    bool? isPermanent,
    Timestamp? suspendedAt,
    Timestamp? expiresAt,
    int? days,
  }) {
    return SuspendUserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      communityId: communityId ?? this.communityId,
      reason: reason ?? this.reason,
      isPermanent: isPermanent ?? this.isPermanent,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      days: days ?? this.days,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'communityId': communityId,
      'reason': reason,
      'isPermanent': isPermanent,
      'suspendedAt': suspendedAt,
      'expiresAt': expiresAt,
      'days': days,
    };
  }

  factory SuspendUserModel.fromMap(Map<String, dynamic> map) {
    return SuspendUserModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      communityId: map['communityId'] as String,
      reason: map['reason'] as String,
      isPermanent: map['isPermanent'] as bool,
      suspendedAt: map['suspendedAt'] as Timestamp,
      expiresAt: map['expiresAt'] != null ? map['expiresAt'] as Timestamp : null,
      days: map['days'] != null ? map['days'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SuspendUserModel.fromJson(String source) => SuspendUserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SuspendUserModel(id: $id, uid: $uid, communityId: $communityId, reason: $reason, isPermanent: $isPermanent, suspendedAt: $suspendedAt, expiresAt: $expiresAt)';
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
      other.suspendedAt == suspendedAt &&
      other.expiresAt == expiresAt &&
      other.days == days;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      uid.hashCode ^
      communityId.hashCode ^
      reason.hashCode ^
      isPermanent.hashCode ^
      suspendedAt.hashCode ^
      expiresAt.hashCode ^
      days.hashCode;
  }
}

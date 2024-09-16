// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMembership {
  final String id;
  final String communityId;
  final String status;
  final String uid;
  final String role;
  final Timestamp joinedAt;
  CommunityMembership({
    required this.id,
    required this.communityId,
    required this.uid,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  CommunityMembership copyWith({
    String? id,
    String? communityId,
    Timestamp? joinedAt,
    String? uid,
    String? role,
    String? status,
  }) {
    return CommunityMembership(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      joinedAt: joinedAt ?? this.joinedAt,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'communityId': communityId,
      'joinedAt': joinedAt,
      'uid': uid,
      'role': role,
        'status': status,
    };
  }

  factory CommunityMembership.fromMap(Map<String, dynamic> map) {
    return CommunityMembership(
      id: map['id'] as String,
      communityId: map['communityId'] as String,
      joinedAt: map['joinedAt'] as Timestamp,
      uid: map['uid'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CommunityMembership.fromJson(String source) =>
      CommunityMembership.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CommunityMembership(id: $id, communityId: $communityId, joinedAt: $joinedAt, uid: $uid, role: $role, status: $status)';
  }

  @override
  bool operator ==(covariant CommunityMembership other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.communityId == communityId &&
        other.joinedAt == joinedAt &&
        other.uid == uid &&
        other.role == role &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        communityId.hashCode ^
        joinedAt.hashCode ^
        uid.hashCode ^
        role.hashCode ^
        status.hashCode;
  }
}


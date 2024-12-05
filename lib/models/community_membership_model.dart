import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMembership {
  final String id;
  final String communityId;
  final String status;
  final String uid;
  final String role;
  final bool isCreator;
  final Timestamp joinedAt;
  CommunityMembership({
    required this.id,
    required this.communityId,
    required this.status,
    required this.uid,
    required this.role,
    required this.isCreator,
    required this.joinedAt,
  });

  CommunityMembership copyWith({
    String? id,
    String? communityId,
    String? status,
    String? uid,
    String? role,
    bool? isCreator,
    Timestamp? joinedAt,
  }) {
    return CommunityMembership(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      status: status ?? this.status,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      isCreator: isCreator ?? this.isCreator,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'communityId': communityId,
      'status': status,
      'uid': uid,
      'role': role,
      'isCreator': isCreator,
      'joinedAt': joinedAt,
    };
  }

  factory CommunityMembership.fromMap(Map<String, dynamic> map) {
    return CommunityMembership(
      id: map['id'] as String,
      communityId: map['communityId'] as String,
      status: map['status'] as String,
      uid: map['uid'] as String,
      role: map['role'] as String,
      isCreator: map['isCreator'] as bool,
      joinedAt: map['joinedAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory CommunityMembership.fromJson(String source) =>
      CommunityMembership.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CommunityMembership(id: $id, communityId: $communityId, status: $status, uid: $uid, role: $role, isCreator: $isCreator, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(covariant CommunityMembership other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.communityId == communityId &&
        other.status == status &&
        other.uid == uid &&
        other.role == role &&
        other.isCreator == isCreator &&
        other.joinedAt == joinedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        communityId.hashCode ^
        status.hashCode ^
        uid.hashCode ^
        role.hashCode ^
        isCreator.hashCode ^
        joinedAt.hashCode;
  }
}

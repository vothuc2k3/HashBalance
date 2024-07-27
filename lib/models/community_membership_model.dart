// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMembership {
  final String id;
  final String communityId;
  final Timestamp joinedAt;
  final String uid;
  final String role;
  CommunityMembership({
    required this.id,
    required this.communityId,
    required this.joinedAt,
    required this.uid,
    required this.role,
  });

  CommunityMembership copyWith({
    String? id,
    String? communityId,
    Timestamp? joinedAt,
    String? uid,
    String? role,
  }) {
    return CommunityMembership(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      joinedAt: joinedAt ?? this.joinedAt,
      uid: uid ?? this.uid,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'communityId': communityId,
      'joinedAt': joinedAt,
      'uid': uid,
      'role': role,
    };
  }

  factory CommunityMembership.fromMap(Map<String, dynamic> map) {
    return CommunityMembership(
      id: map['id'] as String,
      communityId: map['communityId'] as String,
      joinedAt: map['joinedAt'] as Timestamp,
      uid: map['uid'] as String,
      role: map['role'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CommunityMembership.fromJson(String source) => CommunityMembership.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CommunityMembership(id: $id, communityId: $communityId, joinedAt: $joinedAt, uid: $uid, role: $role)';
  }

  @override
  bool operator ==(covariant CommunityMembership other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.communityId == communityId &&
      other.joinedAt == joinedAt &&
      other.uid == uid &&
      other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      communityId.hashCode ^
      joinedAt.hashCode ^
      uid.hashCode ^
      role.hashCode;
  }
}

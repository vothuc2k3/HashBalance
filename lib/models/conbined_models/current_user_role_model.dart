import 'dart:convert';

class CurrentUserRoleModel {
  final String uid;
  final String communityId;
  final String role;
  final String status;
  CurrentUserRoleModel({
    required this.uid,
    required this.communityId,
    required this.role,
    required this.status,
  });

  CurrentUserRoleModel copyWith({
    String? uid,
    String? communityId,
    String? role,
    String? status,
  }) {
    return CurrentUserRoleModel(
      uid: uid ?? this.uid,
      communityId: communityId ?? this.communityId,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'communityId': communityId,
      'role': role,
      'status': status,
    };
  }

  factory CurrentUserRoleModel.fromMap(Map<String, dynamic> map) {
    return CurrentUserRoleModel(
      uid: map['uid'] as String,
      communityId: map['communityId'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CurrentUserRoleModel.fromJson(String source) =>
      CurrentUserRoleModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CurrentUserRoleModel(uid: $uid, communityId: $communityId, role: $role, status: $status)';
  }

  @override
  bool operator ==(covariant CurrentUserRoleModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.communityId == communityId &&
        other.role == role &&
        other.status == status;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        communityId.hashCode ^
        role.hashCode ^
        status.hashCode;
  }
}

import 'dart:convert';

import 'package:hash_balance/models/user_model.dart';

class CurrentUserRoleModel {
  final UserModel user;
  final String communityId;
  final String role;
  final String status;
  CurrentUserRoleModel({
    required this.user,
    required this.communityId,
    required this.role,
    required this.status,
  });

  CurrentUserRoleModel copyWith({
    UserModel? user,
    String? communityId,
    String? role,
    String? status,
  }) {
    return CurrentUserRoleModel(
      user: user ?? this.user,
      communityId: communityId ?? this.communityId,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'user': user.toMap(),
      'communityId': communityId,
      'role': role,
      'status': status,
    };
  }

  factory CurrentUserRoleModel.fromMap(Map<String, dynamic> map) {
    return CurrentUserRoleModel(
      user: UserModel.fromMap(map['user'] as Map<String, dynamic>),
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
    return 'CurrentUserRoleModel(user: $user, communityId: $communityId, role: $role, status: $status)';
  }

  @override
  bool operator ==(covariant CurrentUserRoleModel other) {
    if (identical(this, other)) return true;

    return other.user == user &&
        other.communityId == communityId &&
        other.role == role &&
        other.status == status;
  }

  @override
  int get hashCode {
    return user.hashCode ^
        communityId.hashCode ^
        role.hashCode ^
        status.hashCode;
  }
}

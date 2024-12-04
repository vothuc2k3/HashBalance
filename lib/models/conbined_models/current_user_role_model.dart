import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/models/user_model.dart';

class CurrentUserRoleModel {
  final UserModel user;
  final String communityId;
  final String role;
  final String status;
  final Timestamp joinedAt;
  CurrentUserRoleModel({
    required this.user,
    required this.communityId,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  CurrentUserRoleModel copyWith({
    UserModel? user,
    String? communityId,
    String? role,
    String? status,
    Timestamp? joinedAt,
  }) {
    return CurrentUserRoleModel(
      user: user ?? this.user,
      communityId: communityId ?? this.communityId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

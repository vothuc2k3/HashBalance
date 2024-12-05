import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/models/user_model.dart';

class CurrentUserRoleModel {
  final UserModel user;
  final String communityId;
  final String role;
  final bool isCreator;
  final String status;
  final Timestamp joinedAt;
  CurrentUserRoleModel({
    required this.user,
    required this.communityId,
    required this.role,
    required this.isCreator,
    required this.status,
    required this.joinedAt,
  });
}

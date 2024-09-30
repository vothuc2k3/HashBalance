import 'package:hash_balance/models/suspend_user_model.dart';
import 'package:hash_balance/models/user_model.dart';

class SuspendedUserCombinedModel {
  final UserModel user;
  final SuspendUserModel suspension;

  SuspendedUserCombinedModel({
    required this.user,
    required this.suspension,
  });
}

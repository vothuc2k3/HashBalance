import 'package:hash_balance/models/user_model.dart';

class UserReportModel {
  final UserModel reportedUser;
  final UserModel reporter;

  UserReportModel({
    required this.reportedUser,
    required this.reporter,
  });
}

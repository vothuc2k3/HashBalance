import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CommunityReportModel {
  final Community community;
  final UserModel reporter;
  final UserModel communityOwner;

  CommunityReportModel({
    required this.community,
    required this.reporter,
    required this.communityOwner,
  });
}

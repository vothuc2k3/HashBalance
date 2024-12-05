import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_share_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostShareDataModel {
  final PostShare postShare;
  final Post? post;
  final UserModel shareUser;
  final UserModel author;
  final Community community;
  PostShareDataModel({
    required this.postShare,
    required this.post,
    required this.shareUser,
    required this.author,
    required this.community,
  });
}

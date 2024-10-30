import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostDataModel {
  final Post post;
  final UserModel? author;
  final Community? community;
  final List<PollOption>? options;
  PostDataModel({
    required this.post,
    this.author,
    this.community,
    this.options,
  });
}

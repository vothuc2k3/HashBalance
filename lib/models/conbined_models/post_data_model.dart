import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostDataModel {
  final Post post;
  final UserModel? author;
  final Community community;
  PostDataModel({
    required this.post,
    this.author,
    required this.community,
  });

  @override
  String toString() =>
      'PostDataModel(post: $post, author: $author, communty: $community)';
}

import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostReportModel {
  final Post post;
  final UserModel reporter;
  final UserModel postOwner;
  PostReportModel({
    required this.post,
    required this.reporter,
    required this.postOwner,
  });

  @override
  String toString() =>
      'PostReportModel(post: $post, reporter: $reporter, reportedUser: $postOwner)';
}

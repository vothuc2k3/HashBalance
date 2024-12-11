import 'package:hash_balance/models/livestream_comment_model.dart';
import 'package:hash_balance/models/user_model.dart';

class LivestreamCommentViewModel {
  final LivestreamComment comment;
  final UserModel user;
  LivestreamCommentViewModel({
    required this.comment,
    required this.user,
  });
}

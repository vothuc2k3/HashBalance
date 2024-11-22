import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CommentReportModel {
  final CommentModel comment;
  final UserModel reporter;
  final UserModel commentOwner;

  CommentReportModel({
    required this.comment,
    required this.reporter,
    required this.commentOwner,
  });
}

import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CommentDataModel {
  final CommentModel comment;
  final UserModel author;
  CommentDataModel({
    required this.comment,
    required this.author,
  });
}

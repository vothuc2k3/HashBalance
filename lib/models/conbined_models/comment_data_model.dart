import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CommentDataModel {
  final CommentModel comment;
  final UserModel author;
  CommentDataModel({
    required this.comment,
    required this.author,
  });

  factory CommentDataModel.fromMap(Map<String, dynamic> map) {
    return CommentDataModel(
      comment: CommentModel.fromMap(map['comment'] as Map<String, dynamic>),
      author: UserModel.fromMap(map['author'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() =>
      'CommentDataModel(comment: $comment, author: $author)';
}

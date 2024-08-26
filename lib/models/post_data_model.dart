// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostDataModel {
  final Post post;
  final UserModel author;
  final Community communty;
  PostDataModel({
    required this.post,
    required this.author,
    required this.communty,
  });

  @override
  String toString() =>
      'PostDataModel(post: $post, author: $author, communty: $communty)';
}

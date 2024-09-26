import 'package:hash_balance/models/poll_model.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/models/community_model.dart';

class PollDataModel {
  final Poll poll;
  final List<PollOption> options;
  final UserModel author;
  final Community community;

  PollDataModel({
    required this.poll,
    required this.options,
    required this.author,
    required this.community,
  });
}
